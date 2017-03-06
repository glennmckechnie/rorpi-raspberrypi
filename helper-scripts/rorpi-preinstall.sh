#!/bin/bash
#
# Script used in conjunction with https://github.com/glennmckechnie/rorpi-raspberrypi
# to install the prerequisites for a rorpi installation - read only root pi
#
# Author: glenn.mckechnie@gmail.com
#
# Versions
# 0.06: initial upload - numbering syncs with rorpi-readonly.sh script
# 0.07: call check_version function, add a skip weewx option
# 0.08: add variable to allow apt-get options  '-y' in particular
# 0.09: reposition raspi-config, auto replace weewx path in weewx.conf
# 0.10: Add run once logic to check_version. move raspi-config to start first.
#       Fix sed PATH alteration
# 0.11: Use the weewx apt repository.
# 0.12: Add an option to retain systemd. !! Work in progress - breakages may occur !!
# 0.13: Add RTC notes
# 0.14: Colorize - all the better to see the script messages grandma...
#
# Version 0.14

# apt-get provides an option to say yes to installation targets by using the -y string
# set this as required, ie:- apt_optn="-y"  will allow it to be done automatically

red='\e[0;31m'
yellow='\e[1;33m'
cyan='\e[0;36m'
norm='\e[0m'

apt_optn=""

# Currently, the default initmethod is to remove systemd, adjust the following to suit your needs.
#initmethod="sysv"
#initmethod="systemd" 
initmethod="sysv"

echo -e "\n$yellow If you do not wish to install weewx with this script then add 'noweewx'"
echo -e "\n$cyan                  ie:- $0 noweewx $norm\n"
sleep 2
echo -e "\n$yellow If you want to retain systemd, and you're willing to test the result."
echo -e "\n Then edit the 'initmethod' variable within this script"
echo -e "\n          ie: uncomment #initmethod=systemd"
echo -e "\n Feedback on the success or otherwise would be appreciated. $norm"
sleep 4

check_version()
{
  # http://fitnr.com/bash-comparing-version-strings.html used as template.
  tempfile=$RANDOM
  wget -O /tmp/$tempfile https://github.com/glennmckechnie/rorpi-raspberrypi/raw/master/helper-scripts/rorpi-preinstall.sh

  hubversion=$(grep /tmp/$tempfile -e '^# Version ' | awk -F " " '{print $3}')
  thisversion=$(grep "$0" -e '^# Version ' | awk -F " " '{print $3}')
  winner=$(echo -e "$hubversion\n$thisversion" | sed '/^$/d' | sort -V | head -1)
   # limit this to one check per session - that should be more than enough!
   touch /root/check_preinstall
   if [[ "$winner" < $hubversion ]]
   then
     cp /tmp/"$tempfile" /root/rorpi-preinstall."$hubversion".sh
     echo -e "$yellow An updated rorpi-preinstall.sh (Version $hubversion) is available on github."
     echo -e " It is also available here at /root/rorpi-preinstall-newest.sh"
     echo -e "$cyan      bash /root/rorpi-preinstall.$hubversion.sh"
     echo -e "$yellow It is strongly suggested to use this newer version instead. $norm"
   exit 0
   else
     echo -e "$yellow  The script version on github is $hubversion"
     echo -e " This version is $thisversion so doesn't need updating"
     echo -e "                Okay to continue"
     echo -e " This script will continue in 6 seconds $cyan (Ctrl-C to abort) $norm"
     sleep 6
     return 0
   fi
}

# run the check once only - the second run is probably redundant

if [ ! -f /root/check_preinstall ]
then
check_version
fi

cd /root # Yes, we should be there already - but...


if [ ! -f /root/initmethod ]
then 
# do this first as it requires user input and we might have set -y
# for apt-get, also do it only once
  raspi-config

 echo -e "\n\t$yellow Running apt-get update and dist-upgrade \n"
 echo -e "\n\t         This may take awhile... $norm\n"
 apt-get update
 apt-get $apt_optn dist-upgrade

case $initmethod in
        sysv)
         echo -e "\n\t$yellow Installing sysvinit $norm"

         apt-get $apt_optn install sysvinit-core sysvinit-utils

         echo -e "\n\t$yellow We need to reboot to remove systemd $norm"
         echo -e "\n\t$red Waiting 10 seconds before rebooting $norm"
         sleep 2
         echo -e "\n\n\t$yellow Run this script again after the reboot.\n\n"
         touch /root/initmethod
         sleep 4
         echo -e "\n\n\tRepeating: Run this script again after the reboot $norm\n\n"
         sleep 4

         reboot
         exit 1
        ;;
        systemd)
         echo -e "\n$yellow Retaining systemd as our init method "
         echo -e "\n$red nb:- This action is a work in progress $norm"
         ;;
esac
else
 echo -e "\n\t$yellow Continuing the installation, or updating process $norm\n"
rm -f /root/check_preinstall
fi

# possibly hitting this after the reboot required to cleanly remove systemD

cd /root # and we still should be there already - but...
 rm -f /root/initmethod

case $initmethod in
        sysv)
        apt-get $apt_optn remove --purge --auto-remove systemd
        ;;
esac

# continue
apt-get $apt_optn remove --purge --auto-remove systemd

apt-get $apt_optn install lighttpd sqlite3 rsync mc lynx byobu bootlogd multitail gdisk vim-gtk ssmtp iotop sysstat lsof

#apt-get $apt_optn install  ssmtp # optional
#apt-get $apt_optn install iotop sysstat lsof # stress-ng if you want to "test" the install??

# for optional RTC configuration...
# see https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-preinstall#RTC_Optional
apt-get install i2c-tools

# required for weewx, RTC install, ntp setup - remove cruft.
echo -e "\n\t$yellow Purging fake-hwclock and cruft. $norm\n"
apt-get $apt_optn purge fake-hwclock

apt-get purge wolfram-engine desktop-base lightdm lxappearance lxde-common \
lxde-icon-theme lxinput lxpanel lxrandr  lxtask lxterminal triggerhappy \
libreoffice-core libreoffice-common libreoffice-style-galaxy samba-common \
samba-libs squeak-plugins-scratch squeak-vm supercollider

apt-get $apt_optn -f install # while that shouldn't be required.

echo -e "\n\t$yellow Removing apt-get targeted applications - autoremove $norm\n"
apt-get autoremove # this will

case $1 in
        noweewx)
        echo -e "\t\n$cyan NOT installing weewx $norm\n"
        ;;
        *)
           echo -e "\n\t$yellow Setting up the local apt repository with weewx $norm\n"
           curl -s http://weewx.com/keys.html | sudo apt-key add -
           echo "deb [arch=all] http://weewx.com/apt/ squeeze main" | sudo tee /etc/apt/sources.list.d/weewx.list

           echo -e "\n\t$yellow Fetching and Installing weewx $norm\n"
           sudo apt-get update
           sudo apt-get install weewx

           echo -e "\n\t$yellow Completing weewx installation $norm\n"
           # apt-get $apt_optn update # ignoring as we've only just done an update.
           apt-get $apt_optn -f install

           # add html to first ' HTML_ROOT' encountered, this matches with lighttpd's config
           sed -i '/ HTML_ROOT/ s/ \/var\/www\/weewx/ \/var\/www\/html\/weewx # added by rorpi-preinstall/' /etc/weewx/weewx.conf
        ;;
esac

# running mc now to set up directories and stop it complaining when we become read only
mc

echo -e "\n\t$yellow This Raspbian installation has been updated. Also check your weewx installation "
echo -e "\t is working. The next step is to continue with the read only installation steps (or use the"
echo -e "\t rorpi-readonly.sh script) $norm\n"

exit 0
