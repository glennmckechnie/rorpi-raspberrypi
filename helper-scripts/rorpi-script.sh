#!/bin/bash
#
# Original script kindly contributed by ssinfod.
# Many thanks for kick starting this, it was long overdue (and uncovered
# quite a few typos in the process)
#
# Reference:
# https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-readonly
#
# Note: This script must be executed as root. (sudo -i)
# Note: This script should be executed only once.
#       If we execute it more than once, then we should verify the content of: '.bash_logout' and '.bashrc' for root and pi user.
#         
# Version
#  0.1.2: initial version

rorpitar=rorpi-ro-setup.0.0.3.tar.gz
TEMP=""
FOLDER=""

#===============================================================================
# Function
#===============================================================================
backup_file () {
    #echo "$1"
    EXT='.org'
    FILE1=$1
    FILE2=$FILE1$EXT

    if [ -f $FILE2 ];
    then
        echo "SKIP. (File $FILE2 exists)"
    else
        echo "BACK. (File $FILE2 does not exist)"
        cp $FILE1 $FILE2
    fi
}

#===============================================================================
#MAIN
#===============================================================================
STRING="Script begin..."
echo $STRING

# check if we are running on a raspberry pi, if so assume
# it's okay to continue, if not Panic!

grep /boot/issue.txt -e Raspberry > /dev/null 2>&1
if (( $? != "0" ))
then
 echo "Not a raspberry pi, aborting script."
 exit 1 # exit with error
fi

# This script must be executed under root (ie: 'sudo -i')
# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1 # exit with error
fi

cd /root

# Check for existence of file (see script end) and abort if present
if [  -f /root/rorpi-ro-setup/done-once-already ]
then
    echo " Aborting script as it has already been run. "
    exit 1 # exit with error
fi

# We've passed all tests, we can continue

#Download 'rorpi-ro-setup-x.x.x.x.tar.gz' in the /root folder.
if [ -f $rorpitar ];
then
    echo "SKIP. (File $rorpitar exists)"
else
    echo "WGET. (File $rorpitar does not exist)"
    wget https://github.com/glennmckechnie/rorpi-raspberrypi/raw/master/$rorpitar --no-check-certificate
    tar -zxf $rorpitar
fi

#Change directory to root
cd /root

# Backup file
backup_file '/boot/cmdline.txt'
backup_file '/etc/dphys-swapfile'
backup_file '/etc/fstab'
backup_file '/etc/inittab'
backup_file '/etc/motd'
backup_file '/etc/ntp.conf'
backup_file '/etc/resolv.conf'
backup_file '/etc/default/tmpfs'
#           '/etc/default/voyage-util' (not present)
backup_file '/etc/init.d/checkroot-bootclean.sh'
#           '/etc/init.d/voyage-sync' (not present)


#Create directories
mkdir /etc/lighttpd
mkdir /lib/voyage-utils
mkdir /ro/
mkdir /ro/home
mkdir /ro/home/pi
mkdir /ro/var
mkdir /ro/var/cache
mkdir /ro/var/cache/unbound
mkdir /ro/var/lib
mkdir /ro/var/lib/dhcp
mkdir /ro/var/lib/dhcpcd5 # (even though it's obvious if you read the actual script)
mkdir /ro/var/lib/logrotate
mkdir /ro/var/lib/ntp
mkdir /ro/var/spool
mkdir /ro/var/spool/cron
#mkdir /ro/var/spool/cron/crontabs # copy this instead
mkdir /ro/var/spool/rsyslog
mkdir /ro/var/www
mkdir /ro/var/www/html
mkdir /ro/var/www/html/weewx
mkdir /var/www       # if lighttpd is not installed
mkdir /var/www/html  # if lighttpd is not installed

# Create tmp directories. (needed for the symlink below)
# Note: See also below for chown on ntp folder.
mkdir /tmp/var
mkdir /tmp/var/cache
mkdir /tmp/var/cache/unbound
mkdir /tmp/var/lib
mkdir /tmp/var/lib/dhcp
mkdir /tmp/var/lib/dhcpcd5
mkdir /tmp/var/lib/logrotate
mkdir /tmp/var/lib/ntp
mkdir /tmp/var/spool
mkdir /tmp/var/spool/cron
mkdir /tmp/var/spool/rsyslog
mkdir /tmp/var/www
mkdir /tmp/var/www/html

#We assign 'rorpi-ro-setup' in FOLDER because of the 'tar -xyz' made above.
FOLDER='rorpi-ro-setup'

#boot
cp ./$FOLDER/boot/cmdline.txt.rorpi /boot/cmdline.txt

#etc
cp ./$FOLDER/etc/dphys-swapfile.rorpi /etc/dphys-swapfile
cp ./$FOLDER/etc/fstab.rorpi /etc/fstab
cp ./$FOLDER/etc/inittab.rorpi /etc/inittab
cp ./$FOLDER/etc/motd.rorpi /etc/motd
cp ./$FOLDER/etc/ntp.conf.rorpi /etc/ntp.conf
#cp ./$FOLDER/etc/resolv.conf.rorpi /run/resolv.conf            # which one is it ??
#cp ./$FOLDER/etc/resolv.conf.rorpi /run/resolvconf/resolv.conf # which one is it ??
# probably neither
cp ./$FOLDER/etc/default/tmpfs.rorpi /etc/default/tmpfs
cp ./$FOLDER/etc/default/voyage-util /etc/default/voyage-util
cp ./$FOLDER/etc/init.d/checkroot-bootclean.sh.rorpi /etc/init.d/checkroot-bootclean.sh
cp ./$FOLDER/etc/init.d/voyage-sync /etc/init.d/voyage-sync
cp ./$FOLDER/etc/lighttpd/lighttpd.conf.rorpi /etc/lighttpd/lighttpd.conf
cp -Rp ./$FOLDER/ro/var/spool/cron/crontabs /ro/var/spool/cron/crontabs # copied rather than created


#Create link1 (soft?)
rm /etc/resolv.conf
ln -sf /etc/resolvconf/run/resolv.conf /etc/resolv.conf

#Create link2 (soft?)
cd /etc/resolvconf
ln -sf /run/resolvconf run
cd /root

#Copy the other files to folder
cp ./$FOLDER/lib/voyage-utils/100-rpi /lib/voyage-utils/

#bash

if [ -f "./$FOLDER/root/.bashrc-append.rorpi.done" ]
then 
  #Warning: Execute script only once.
  STRING="Note:We shoud append text only once to .bash_logout and .bashrc"
  echo $STRING
else
  cat ./$FOLDER/root/.bash_logout.rorpi >> /root/.bash_logout     #append only once.
  cat ./$FOLDER/root/.bash_logout.rorpi >> /etc/skel/.bash_logout #append only once
  cat ./$FOLDER/root/.bashrc-append.rorpi >> /root/.bashrc        #append only once?
  cat ./$FOLDER/root/.bashrc-append.rorpi >> /etc/skel/.bashrc    #append only once?

  cat ./$FOLDER/root/.bash_logout.rorpi >> /home/pi/.bash_logout
  cat ./$FOLDER/root/.bashrc-append.rorpi >> /home/pi/.bashrc #append only once?

  mv ./$FOLDER/root/.bash_logout.rorpi ./$FOLDER/root/.bash_logout.rorpi.done
  mv ./$FOLDER/root/.bashrc-append.rorpi ./$FOLDER/root/.bashrc-append.rorpi.done
fi

#Helper scripts to remount
cp ./$FOLDER/usr/local/sbin/fastreboot /usr/local/sbin/fastreboot
cp ./$FOLDER/usr/local/sbin/remountro /usr/local/sbin/remountro
cp ./$FOLDER/usr/local/sbin/remountrw /usr/local/sbin/remountrw
cp ./$FOLDER/usr/local/sbin/remove.docs /usr/local/sbin/remove.docs
cd /usr/local/sbin
ln -sf remountro rero  # create softlinks as it makes it obvious they are duplicate files
ln -sf remountrw rerw

cd /root

#Symlink to tmp
rm -rf /var/cache/unbound && ln -sf /tmp/var/cache/unbound /var/cache/unbound
rm -rf /var/lib/dhcp && ln -sf /tmp/var/lib/dhcp /var/lib/dhcp
rm -rf /var/lib/dhcpcd5 && ln -sf /tmp/var/lib/dhcpcd5 /var/lib/dhcpcd5
rm -rf /var/lib/logrotate && ln -sf /tmp/var/lib/logrotate /var/lib/logrotate
rm -rf /var/lib/ntp && ln -sf /tmp/var/lib/ntp /var/lib/ntp
rm -rf /var/spool/cron && ln -sf /tmp/var/spool/cron /var/spool/cron
rm -rf /var/spool/rsyslog && ln -sf /tmp/var/spool/rsyslog /var/spool/rsyslog
rm -rf /var/www/html && ln -sf /tmp/var/www/html /var/www/html

#Give proper ownership
#chown pi:pi /home/pi/.bash_logout # probably redundant, removing to check
#chown pi:pi home/pi/.bashrc
cd /var/lib
chown ntp.ntp ntp

#init script and swap
update-rc.d voyage-sync defaults
update-rc.d  dphys-swapfile disable

touch /root/rorpi-ro-setup/done-once-already

STRING="Script end."
echo $STRING

STRING="You can now reboot the RPI with 'reboot -n'"
echo $STRING

exit 0 # exited successfully

#END
