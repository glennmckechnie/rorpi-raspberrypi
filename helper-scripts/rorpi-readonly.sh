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
#       If we execute it more than once, then we should verify the content of: 
#       '.bash_logout' and '.bashrc' for root and pi user.
#         
# Version
# 0.1.1: initial version. Kindly contributed by ssinfod
# 0.02: (was 0.1.2) introduce system check (run only on a raspberry pi only). Add stop file
#       so we can only run this once. Fix resolvconf confusion. Copy crontab rather than create
#       (due to group and permission issues). Remove touch's as they are now redundant. Add check
#       for .bash* cats (we do only want to do them once). Softlinks for rerw and rero.
#       Remove /ro/home/pi templates. Checked with the assistance of ssinfod
# 0.03: (was 0.1.3) make use of mkdir -p to simplify process. Add weewx/NOAA directory. Checked
#       with the assistance of ssinfod
# 0.04: introduce version self check. Reinstate /ro/home/pi/*.rorpi as templates for /home/pi. 
#       Add feedback messages. Remove pi/.bash* templates from /ro area (not needed as we use /home/pi)
# 0.05: Add full path to aliases. Include helper-scripts directory. Simplify version number
# 0.06: Change script name to rorpi-readonly.sh pre introduction of new script.
#       rorpi-preinstall.sh now available for preliminary steps.
# 0.07: Consolidate name change
# 0.08: Fix creation of www directory
# 0.09: Add run once logic to check_version. Remove errant paste
#
# Version 0.10


rorpitar_version=10 # keep this in sync with the last 2 numbers of latest Version number above,
                    # as tarball will probably be updated as well
rorpitar=rorpi-ro-setup.0."$rorpitar_version".tar.gz

FOLDER=""

#===============================================================================
# Function
#===============================================================================
check_version()
{
  # http://fitnr.com/bash-comparing-version-strings.html used as template.
  tempfile=$RANDOM
  wget -O /tmp/$tempfile https://github.com/glennmckechnie/rorpi-raspberrypi/raw/master/helper-scripts/rorpi-readonly.sh

  hubversion=$(grep /tmp/$tempfile -e '^# Version ' | awk -F " " '{print $3}')
  thisversion=$(grep "$0" -e '^# Version ' | awk -F " " '{print $3}')
  winner=$(echo -e "$hubversion\n$thisversion" | sed '/^$/d' | sort -V | head -1)
   # limit this to one check per session - that should be more than enough!
   touch /tmp/check_readonly
   if [[ "$winner" < $hubversion ]]
   then
     cp /tmp/"$tempfile" /root/rorpi-readonly."$hubversion".sh
     echo " "An updated rorpi-readonly.sh "(Version $hubversion)" is available on github.
     echo " "It is now available here at /root/rorpi-readonly."$hubversion".sh
     echo "      "bash /root/rorpi-readonly-"$hubversion".sh
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

backup_file () {
    EXT='.org'
    FILE1=$1
    FILE2=$FILE1$EXT

    if [ -f $FILE2 ];
    then
        echo "SKIP. (File $FILE2 exists, ignoring backup)"
    else
        echo "BACK. (File $FILE2 did not exist, now copying)"
        cp $FILE1 $FILE2
    fi
}

#===============================================================================
#MAIN
#===============================================================================
STRING="Script begin..."
echo $STRING

# We don't want any accidents so we'll check if we are running on a raspberry pi
# and if so assume it's okay to continue, if not we Panic! 

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

# run the check once only - the second run is probably redundant

if [ ! -f /tmp/check_readonly ]
then
check_version
fi


# Finally! Start the actual script.

cd /root

# But, check for the existence of a file that indicates we've run this once already
# (see the end of this script) and abort if present
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
echo -e "\tBacking up files to *.org"
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
echo -e "\tCreating directories"
mkdir /etc/lighttpd
mkdir /lib/voyage-utils
mkdir -p /ro/home/pi
mkdir -p /ro/var/cache/unbound
mkdir -p /ro/var/lib/dhcp
mkdir /ro/var/lib/dhcpcd5 # (even though it's obvious if you read the actual script)
mkdir /ro/var/lib/logrotate
mkdir /ro/var/lib/ntp
mkdir -p /ro/var/spool/cron
mkdir /ro/var/spool/rsyslog
mkdir -p /ro/var/www/html/weewx/NOAA  # if lighttpd is not installed

# Create tmp directories. (needed for the symlink below)
# Note: See also below for chown on ntp folder.
echo -e "\tCreating /tmp directories"
mkdir -p /tmp/var/cache/unbound
mkdir -p /tmp/var/lib/dhcp
mkdir /tmp/var/lib/dhcpcd5
mkdir /tmp/var/lib/logrotate
mkdir /tmp/var/lib/ntp
mkdir -p /tmp/var/spool/cron
mkdir /tmp/var/spool/rsyslog
mkdir -p /tmp/var/www/html/weewx/NOAA

#We assign 'rorpi-ro-setup' in FOLDER because of the 'tar -xyz' made above.
FOLDER='rorpi-ro-setup'

#boot
echo -e "\tCopying system files"
cp ./$FOLDER/boot/cmdline.txt.rorpi /boot/cmdline.txt

#etc
cp ./$FOLDER/etc/dphys-swapfile.rorpi /etc/dphys-swapfile
cp ./$FOLDER/etc/fstab.rorpi /etc/fstab
cp ./$FOLDER/etc/inittab.rorpi /etc/inittab
cp ./$FOLDER/etc/motd.rorpi /etc/motd
cp ./$FOLDER/etc/ntp.conf.rorpi /etc/ntp.conf
cp ./$FOLDER/etc/default/tmpfs.rorpi /etc/default/tmpfs
cp ./$FOLDER/etc/default/voyage-util /etc/default/voyage-util
cp ./$FOLDER/etc/init.d/checkroot-bootclean.sh.rorpi /etc/init.d/checkroot-bootclean.sh
cp ./$FOLDER/etc/init.d/voyage-sync /etc/init.d/voyage-sync
cp ./$FOLDER/etc/lighttpd/lighttpd.conf.rorpi /etc/lighttpd/lighttpd.conf
cp -Rp ./$FOLDER/ro/var/spool/cron/crontabs /ro/var/spool/cron/crontabs # copied rather than created tp preserve group and permissions


#Create link1 (soft?)
echo -e "\tCreating symlinks"
rm /etc/resolv.conf
ln -sf /etc/resolvconf/run/resolv.conf /etc/resolv.conf

#Create link2 (soft?)
cd /etc/resolvconf
ln -sf /run/resolvconf run
cd /root

#bash
echo -e "\tSetting up bash aliases, and extras"

if [ -f "./$FOLDER/root/.bashrc-append.rorpi.done" ]
then 
  #Warning: Execute script only once.
  echo "Skipping the .bash* step!"
  echo "Note: We shoud append text only once to .bash_logout and .bashrc"
  echo "and we've done it already"
else
  cat ./$FOLDER/root/.bash_logout.rorpi >> /root/.bash_logout
  cat ./$FOLDER/root/.bashrc-append.rorpi >> /root/.bashrc

  cat ./$FOLDER/ro/home/pi/.bash_logout.rorpi >> /etc/skel/.bash_logout
  cat ./$FOLDER/ro/home/pi/.bashrc-append.rorpi >> /etc/skel/.bashrc
  cat ./$FOLDER/ro/home/pi/.bash_logout.rorpi >> /home/pi/.bash_logout
  cat ./$FOLDER/ro/home/pi/.bashrc-append.rorpi >> /home/pi/.bashrc

  mv ./$FOLDER/root/.bash_logout.rorpi ./$FOLDER/root/.bash_logout.rorpi.done
  mv ./$FOLDER/root/.bashrc-append.rorpi ./$FOLDER/root/.bashrc-append.rorpi.done #setup skip test
  rm -f ./$FOLDER/ro/home/pi/.bash_logout.rorpi
  rm -f ./$FOLDER/ro/home/pi/.bashrc-append.rorpi
fi

#Copy the other files to folder
echo -e "\tCopying remaining files, helper scripts"
cp ./$FOLDER/lib/voyage-utils/100-rpi /lib/voyage-utils/

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
echo -e "\tSetting up critical folder links"
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
echo -e "\tRunning update-rc.d to enable voyage-sync" 
update-rc.d voyage-sync defaults
update-rc.d  dphys-swapfile disable

echo -e "\tCreating lock file to prevent this script running again"
touch /root/rorpi-ro-setup/done-once-already
ls -al /root/rorpi-ro-setup/done-once-already

STRING="Script end."
echo $STRING

STRING="You can now reboot the RPI with 'reboot -n'"
echo $STRING

exit 0 # exited successfully

#END
