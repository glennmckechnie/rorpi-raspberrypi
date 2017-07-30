#!/bin/bash
# script to write image file to SDCard
# run this from the command line with  "bash -x sdcard_write_read_confirm.sh" to get #!/bin/bash -x behaviour of old
#
# sdcard_write_read_confirm.sh
#
# my oh my! hasn't bash changed
# created with shellcheck and vim - no error goes unpunished.
#
#-# Glenn McKechnie - modified 21/04/16 
# GPL'd if anyone needs to ask.

red='\e[0;31m'
yellow='\e[1;33m'
cyan='\e[0;36m'
norm='\e[0m'

filetype=""
basedir=$(pwd)
devyce=$1
image=$2
action=$3
tymestamp=$(date "+%Y%m%d%H%M")
unset type_p
export response=""


call_usage(){
if [ $# -ne 3 ]
then
    echo -e "\n\\033[35m Usage: $0 <device> <imagefile> <action>\\033[0;39m"
    echo -e "\n $yellow eg:- $0 /dev/sde voyage-mubox-4.img write"
    echo -e "$yellow A script to write, read, and confirm image files (*.img) to disk"
    echo -e " cd to location of the image file to be written. Then, run this script"
    echo -e " and pay attention to the questions it may ask, or response it gives"
    echo -e " It attempts to save your butt, but it can't think... thankfully we can.\n"
    echo -e "$red (Need to use sudo or be root to run it too. Either way - be careful!) $norm"
    exit 1
fi

}

call_pause(){
  echo -e "\n$yellow   Type in yes (then Enter) if this is the correct device\n"
  echo -e "\n   Typing anything else will abort the process or use Ctrl-C $norm\n"
  read response
  case $response in
        yes)
           printf "\n Working with %s and %s for a %s \n\n\n" $image $devyce $action
           ;;
          *)
           printf "\n\tAborting this program on user request\n\n"
           exit 0
           ;;
  esac
}

check_disk(){
part_n=/$(echo "$devyce" | awk -F / '{print $3}')1/
#type_p=$(fdisk -l "$devyce" | awk '/W95/{print $9}')
#-# Glenn McKechnie - modified 22/04/16 
#type_p=$(fdisk -l "$devyce" | awk '/sde1/{print $8}')
type_p=$(sudo /sbin/fdisk -l "$devyce" | /usr/bin/awk ''$part_n'{print $8}')

if [ "$type_p" = "FAT32" ]
    then
      printf "\n\tThe device appears to be a Windows, or valid, device\n\tPlease confirm if it is okay to erase its contents?\n"
      #pause "$image $devyce"
    else
      printf "\n\n  Aborting script as this (%s) doesn't appear to be a\n\t\t suitable partion (Windows FAT32)\n" $devyce
      sleep 2
      echo -e "\n\nare you really, really sure??\n\n"
      exit 0
fi
}

call_me () {
me="/home/graybeard/github/rorpi-raspberrypi/helper-scripts/"
if [ -d $me ]
then
  mkdir -p /mnt/sdcard
  mount "${devyce}2" /mnt/sdcard
  mount "${devyce}1" /mnt/sdcard/boot

  #cp /home/graybeard/rorpi-temp/config.txt /mnt/sdcard/boot/
  cp -r $me/* /mnt/sdcard/root/
  sed -i '/apt_optn/ s/\"\"/\"-y\"/ # added by script' /mnt/sdcard/root/rorpi-preinstall.sh
  touch /mnt/sdcard/$tymestamp-rorpi-finished
  sync

  umount /mnt/sdcard/boot
  umount /mnt/sdcard
fi
}

############## main ###########


call_usage  "$devyce" "$image" "$action"

if [ ! -f "${basedir}/${image}" ]
then 
        printf "\nThe image file ( %s ) was not found in this directory\n( %s )\n" "${image}" "${basedir}"
        call_usage
        exit 1
fi

# because Firefox et al insist on downloading an extension less file, and I invariably forget to Unzip it.
filetype=$(/usr/bin/file "${basedir}/${image}" | awk '/: /{print $2}')
case $filetype in
        Zip)
        echo
        #/usr/bin/file "${basedir}/${image}"
        echo -e "$yellow Specified file is a Zip file, now unpacking it $cyan"
        /usr/bin/unzip "${basedir}/${image}"
        echo -e "$yellow Restart this script with the above filename as the image file! $norm"
        exit 0
        echo
        ;;
        DOS/MBR)
        echo -e "$yellow Image file identifies as... $cyan"
        /usr/bin/file "${basedir}/${image}"
        echo -e "$yellow Now checking device specified... $norm"

      sudo fdisk -l # shows us the last entry - which should be our just plugged in SDCard?
      echo -e "\n\n\n\t\t$red We begin here...\nPay attention to the drive size - is that really your SDCard? $norm\n\n\n"
      sudo /sbin/fdisk -l "$devyce"
      # comment out the following line if you don't want, or if the function to check, for a valid
      # FAT32 - W95 partition is giving you grief - With that done, and when running the script you
      # must pay close attention to your answer regarding the correct device!
      check_disk
      call_pause "$image $devyce"

#exit 0 #test stop
echo action = "$action"
          case $action in
                write)
                 sync
                 sudo /bin/dd if="${basedir}/${image}" of="$devyce" conv=noerror,sync bs=4M status=progress
                 sync
                ;;
                read)
                 sync
                 sudo /bin/dd if="${devyce}" of="${basedir}/${tymestamp}-${image}" conv=noerror,sync bs=4M status=progress
                 sync
                ;;
                confirm)
                 sudo /usr/bin/md5sum "${basedir}/$image" "${basedir}/${tymestamp}-$image"
                ;;
                *)
                 echo -e "\n$red Unknown action (should be write, read, or confirm) -- aborting process $norm\n"
                 call_usage
                 exit 1
                ;;
          esac
        ;;
        *)
        echo -e "$yellow Unknown image file type -- aborting process $norm"
                 exit 1
        ;;
esac

# call_me is used to transfer files to the fresh image, before we run it for the first time
# In my case I need to modify config.txt to be able to make the HDMI display readable.
# I also transfer copies of the rorpi helper-scripts to get things started.
# It will skip if it's not me!

call_me "$devyce"

exit 0

# Typical output from fdisk -l for a Sandisk cruzer 8G USB stick
# pre image write

#Disk /dev/sde: 7.4 GiB, 7948206080 bytes, 15523840 sectors
#Units: sectors of 1 * 512 = 512 bytes
#Sector size (logical/physical): 512 bytes / 512 bytes
#I/O size (minimum/optimal): 512 bytes / 512 bytes
#Disklabel type: dos
#Disk identifier: 0xe4306ba2

#Device     Boot Start      End  Sectors  Size Id Type
#/dev/sde1  *     2048 15523839 15521792  7.4G  c W95 FAT32 (LBA)


# post image write
#Disk /dev/sde: 7.4 GiB, 7948206080 bytes, 15523840 sectors
#Units: sectors of 1 * 512 = 512 bytes
#Sector size (logical/physical): 512 bytes / 512 bytes
#I/O size (minimum/optimal): 512 bytes / 512 bytes
#Disklabel type: dos
#Disk identifier: 0xe4306ba2

#Device     Boot  Start      End  Sectors  Size Id Type
#/dev/sde1         2048   133119   131072   64M  c W95 FAT32 (LBA)
#/dev/sde2       133120 15523839 15390720  7.3G 83 Linux

