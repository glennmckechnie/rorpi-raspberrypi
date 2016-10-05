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
#
# Version 0.09

# apt-get provides an option to say yes to installation targets by using the -y string
# set this as required, ie:- apt_optn="-y"  will allow it to be done automatically
apt_optn=""

weewx_version="weewx_3.5.0-1_all.deb"

echo -e "\nIf you do not wish to install weewx then add 'noweewx'"
echo -e "\n ie:- $0 noweewx\n"
sleep 2

check_version()
{
  # http://fitnr.com/bash-comparing-version-strings.html used as template.
  tempfile=$RANDOM
  wget -O /tmp/$tempfile https://github.com/glennmckechnie/rorpi-raspberrypi/raw/master/helper-scripts/rorpi-preinstall.sh

  hubversion=$(grep /tmp/$tempfile -e '^# Version ' | awk -F " " '{print $3}')
  thisversion=$(grep "$0" -e '^# Version ' | awk -F " " '{print $3}')
  winner=$(echo -e "$hubversion\n$thisversion" | sed '/^$/d' | sort -V | head -1)
   if [[ "$winner" < $hubversion ]]
   then
     cp /tmp/"$tempfile" /root/rorpi-preinstall."$hubversion".sh
     echo " "An updated rorpi-preinstall.sh "(Version $hubversion)" is available on github.
     echo " "It is also available here at /root/rorpi-preinstall-newest.sh
     echo "      "bash /root/rorpi-preinstall."$hubversion".sh
     echo " "It is strongly suggested to use this newer version instead.
   exit 0
   else
     echo "script version on github is $hubversion"
     echo "This version is $thisversion so doesn't need updating"
     echo "This script will continue in 6 seconds (Ctrl-C to abort)"
     sleep 6
     return 0
   fi
}


check_version

cd /root # Yes, we should be there already - but...

# do this first as it requires user input and we might have set -y for apt-get
  raspi-config

if [ ! -f /root/remove_systemd ]
then 
 echo -e "\n\tRunning apt-get update and dist-upgrade\n"
 apt-get update
 apt-get $apt_optn dist-upgrade

 echo -e "\n\tInstalling sysvinit"

 apt-get $apt_optn install sysvinit-core sysvinit-utils

 echo -e "\n\tWe need to reboot to remove systemd"
 echo -e "\n\tWaiting 6 seconds before rebooting"
 sleep 2
 echo -e "\n\n\tRun this script again after the reboot\n\n"
 touch /root/remove_systemd
 sleep 4

 reboot
 exit 1
else
 echo -e "\n\tContinuing installation, updating  process\n"
fi

cd /root # and we still should be there already - but...
 rm -f /root/remove_systemd

apt-get $apt_optn remove --purge --auto-remove systemd

apt-get $apt_optn install lighttpd sqlite3 rsync mc lynx byobu bootlogd multitail gdisk vim-gtk ssmtp iotop sysstat lsof

#apt-get $apt_optn install  ssmtp # optional
#apt-get $apt_optn install iotop sysstat lsof # stress-ng if you want to "test" the install??

echo -e "\n\tPurging fake -hwclock\n"
apt-get $apt_optn purge fake-hwclock

apt-get purge wolfram-engine desktop-base lightdm lxappearance lxde-common\
lxde-icon-theme lxinput lxpanel lxrandr  lxtask lxterminal triggerhappy\
libreoffice-core libreoffice-common libreoffice-style-galaxy samba-common\
samba-libs squeak-plugins-scratch squeak-vm supercollider

apt-get $apt_optn -f install # while that shouldn't be required.

echo -e "\n\tRemoving apt-get targeted applications - autoremove\n"
apt-get autoremove # this will

case $1 in
	noweewx)
	echo -e "\t\nNOT installing weewx\n"
	;;
	*)
           echo -e "\n\tFetching and Installing weewx\n"
           wget http://weewx.com/downloads/$weewx_version
           sudo dpkg -i $weewx_version
	   # add html to first ' HTML_ROOT' encountered, this matches with lighttpd's config
	   sed -i '/ HTML_ROOT/ s/ \/var\/www\/weewx/ \/var\/www\/weewx\/html # added by rorpi-preinstall/' /etc/weewx/weewx.conf

           echo -e "\n\tCompleting weewx installation\n"
           # apt-get $apt_optn update # ignoring as we've only just done an update.
           apt-get $apt_optn -f install
	;;
esac

echo -e "\n\tInstallation has been completed. Check your weewx installation is working"
echo -e "\tand then continue with the read only installation steps (or use the"
echo -e "\trorpi-readonly.sh script)\n"

