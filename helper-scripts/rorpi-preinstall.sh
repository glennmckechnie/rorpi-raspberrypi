#!/bin/bash
#
# Version
# 0.06: initial upload - numbering syncs with rorpi-readonly.sh script
# 0.07: call check function
#
# Version 0.07

weewx_version="weewx_3.5.0-1_all.deb"

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
     cp "/tmp/$tempfile" "/tmp/rorpi-preinstall-$hubversion-$tempfile.sh"
     echo " "An updated rorpi-preinstall.sh "(Version $hubversion)" is available on github.
     echo " "It is also available here at /tmp/rorpi-preinstall-"$hubversion"-"$tempfile".sh
     echo "      "bash /tmp/rorpi-preinstall-"$hubversion"-"$tempfile".sh
     echo " "It is strongly suggested to replace this script "(Version $thisversion)" and use it instead.
     echo "   "cp /tmp/rorpi-preinstall-"$hubversion"-"$tempfile".sh "$0"
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

if [ ! -f /root/remove_systemd ]
then 
 echo -e "\n\tRunning apt-get update and dist-upgrade\n"
 apt-get update
 apt-get dist-upgrade

  raspi-config

 echo -e "\n\tInstalling sysvinit"

 apt-get install sysvinit-core sysvinit-utils

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

apt-get remove --purge --auto-remove systemd

apt-get install lighttpd sqlite3 rsync mc lynx byobu bootlogd multitail gdisk vim-gtk ssmtp iotop sysstat lsof

#apt-get install  ssmtp # optional
#apt-get install iotop sysstat lsof # stress-ng if you want to "test" the install??

echo -e "\n\tPurging fake -hwclock\n"
apt-get purge fake-hwclock

apt-get purge wolfram-engine desktop-base lightdm lxappearance lxde-common\
lxde-icon-theme lxinput lxpanel lxrandr  lxtask lxterminal triggerhappy\
libreoffice-core libreoffice-common libreoffice-style-galaxy samba-common\
samba-libs squeak-plugins-scratch squeak-vm supercollider

apt-get -f install # while that shouldn't be required.

echo -e "\n\tremoving apt-get targeted applications - autoremove\n"
apt-get autoremove # this will

echo -e "\n\tFetching and Installing weewx\n"
wget http://weewx.com/downloads/$weewx_version
sudo dpkg -i $weewx_version

echo -e "\n\tCompleting weewx installation\n"
apt-get update
apt-get -f install

echo -e "\n\tInstallation has been completed. Check your weewx installation is working"
echo -e "\tand then continue with the read only installation steps (or use the"
echo -e "\trorpi-readonly.sh script)\n"

