#!/bin/bash
# Reference:
# https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-readonly
#
# Note: This script must be executed as root. (sudo -i)
# Note: This script should be executed only once.
#       If we execute it more than once, then we should verify the content of: '.bash_logout' and '.bashrc' for root and pi user.
#         
# Version
#  0.1.1: initial version

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
TEMP=""
FOLDER=""
STRING="Script begin..."
echo $STRING

# This script must be executed under root (ie: 'sudo -i')
# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
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

#Download 'rorpi-ro-setup-x.x.x.x.tar.gz' in the /root folder.
TEMP=rorpi-ro-setup.0.0.2.0.tar.gz
cd /root
if [ -f $TEMP ];
then
    echo "SKIP. (File $TEMP exists)"
else
    echo "WGET. (File $TEMP does not exist)"
    wget https://github.com/glennmckechnie/rorpi-raspberrypi/raw/master/rorpi-ro-setup.0.0.2.0.tar.gz --no-check-certificate
    tar -zxf rorpi-ro-setup.0.0.2.0.tar.gz
fi

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
mkdir /ro/var/spool/cron/crontabs
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
cp ./$FOLDER/etc/resolv.conf.rorpi /run/resolv.conf            # which one is it ??
cp ./$FOLDER/etc/resolv.conf.rorpi /run/resolvconf/resolv.conf # which one is it ??
cp ./$FOLDER/etc/default/tmpfs.rorpi /etc/default/tmpfs
cp ./$FOLDER/etc/default/voyage-util /etc/default/voyage-util
cp ./$FOLDER/etc/init.d/checkroot-bootclean.sh.rorpi /etc/init.d/checkroot-bootclean.sh
cp ./$FOLDER/etc/init.d/voyage-sync /etc/init.d/voyage-sync
cp ./$FOLDER/etc/lighttpd/lighttpd.conf.rorpi /etc/lighttpd/lighttpd.conf
#cp ./$FOLDER/etc/resolvconf/run /etc/resolvconf/run  # this is a software link. see below.

#Create link1 (soft?)
rm /etc/resolv.conf
ln -sf /etc/resolvconf/run/resolv.conf /etc/resolv.conf

#Create link2 (soft?)
cd /etc/resolvconf
ln -sf /run/resolvconf run
cd /root

#tosee:alternative?
#cd /etc/resolvconf
#ls -sf /run/resolv.conf run

#Copy the other files to folder
cp ./$FOLDER/lib/voyage-utils/100-rpi /lib/voyage-utils/

#Create stub
#touch /ro/var/cache/unbound/empty-stub
#touch /ro/var/lib/dhcp/empty-stub
#touch /ro/var/lib/dhcpcd5/empty-stub
#touch /ro/var/lib/logrotate/empty-stub
#touch /ro/var/lib/ntp/empty-stub
#touch /ro/var/spool/cron/crontabs/empty-stub
#touch /ro/var/spool/rsyslog/empty-stub
#touch /ro/var/www/html/weewx/empty-stub

#bash
#Warning: Execute script only once.
STRING="Note:We shoud append text only once to .bash_logout and .bashrc"
echo $STRING

cat ./$FOLDER/root/.bash_logout.rorpi >> /root/.bash_logout     #append only once.
cat ./$FOLDER/root/.bash_logout.rorpi >> /etc/skel/.bash_logout #append only once
cat ./$FOLDER/root/.bashrc-append.rorpi >> /root/.bashrc        #append only once?
cat ./$FOLDER/root/.bashrc-append.rorpi >> /etc/skel/.bashrc    #append only once?

cat ./$FOLDER/root/.bash_logout.rorpi >> /home/pi/.bash_logout
cat ./$FOLDER/root/.bashrc-append.rorpi >> /home/pi/.bashrc #append only once?

#Helper scripts to remount
cp ./$FOLDER/usr/local/sbin/fastreboot /usr/local/sbin/fastreboot
cp ./$FOLDER/usr/local/sbin/remountro /usr/local/sbin/remountro
cp ./$FOLDER/usr/local/sbin/remountrw /usr/local/sbin/remountrw
cp ./$FOLDER/usr/local/sbin/remove.docs /usr/local/sbin/remove.docs
cd /usr/local/sbin
ln -s remountro rero  # create softlinks as it makes it obvious they are duplicate files
ln -s remountrw rerw
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
chown pi:pi /ro/home/pi/.bash_logout
chown pi:pi /ro/home/pi/.bashrc
cd /var/lib
chown ntp.ntp ntp

#init script and swap
update-rc.d voyage-sync defaults
update-rc.d  dphys-swapfile disable

STRING="Script end."
echo $STRING

STRING="You can now reboot the RPI with 'reboot -n'"
echo $STRING

exit 1

#END
