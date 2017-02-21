# rorpi - raspberrypi
A method to run a Raspberry Pi, using the Raspbian distribution, configured with a read only / file system  - thus the name "Read Only Root Pi" or RORPi

It should then be able to run the Weewx weather station software ( http://weewx.com ) with the minimum of upkeep. It's not limited to running the weewx software either, it should be re-configurable for anything else that fits the same criteria.

Like any system that holds valuable information, it will require the addition of a suitable back-up routine. That's not part of this wiki HowTo and will need to be configured for your needs anyway.


### Visit the wiki for greater detail -
https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/Rorpi-Home

### For discussion, visit the google group at -
https://groups.google.com/forum/#!forum/rorpi-discussion

## Updates:
### Feb 2017 
Using weewx's internal report RSYNC skin to perform backups.

https://github.com/weewx/weewx/wiki/Using-the-RSYNC-skin-as-a-backup-solution 


### Feb 2017
* Add notes on setting up a RTC-  https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-preinstall#Time_keeping

### Jan 2017
* Default to using weewx's apt repository for installation of weewx. Simpler for the user, much simpler for the scripting.
* If you are using the helper script (rorpi-preinstall.sh), an option has been added to allow systemd to be retained as the init method. This appears to work without anything breaking too severely, but it's a work in progress and so the option is perhaps only for the adventurous?

### November 2016
New page!<br>
tl;dr ...  Otherwise known as the short version.

https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-tl;dr


### October 2016

Scripts have been added (in the helper-scripts directory), along with a gzipped tarball (in the main directory) of the required files and directories. This is to preserve ownership and permissions of the required files, and as it turns out helps in the automation of the read-only installation process.

The script *rorpi-readonly.sh* has been contributed by ssinfod. It can be run to automatically download that compressed file, unpack its contents accordingly and perform the necessary actions to turn the system into a read-only one. As its name suggests **bash rorpi-readonly.sh** performs the tasks on the readonly wiki page.
https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-readonly


Within the helper-scripts directory, another script (rorpi-preinstall.sh) has been added to perform the actions of the preinstall wiki page.  https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-preinstall
In addition there is also a script *sdcard_write_read_confirm.sh* to help with the initial image transfer described on that page.

* Running *sdcard_write_read_confirm.sh* will assist with the image transfer to the SDCard (providing you are on a Linux machine). Entering the command **bash sdcard_write_read_confirm.sh** will display usage notes. Alternatively you can follow the manual instructions available where you got your Raspbian image. 

* Running *rorpi-preinstall.sh* will give you an updated version of Raspian with the added bonus of a Weewx install. (You can edit that script and perform an automatic apt-get install, effectively answering yes to all questions, by changing  *apt_optn=""* to *apt_optn="-y"*  The script can be run by entering **bash rorpi-preinstall.sh**, it also accepts the option 'noweewx' on the command line if you wish to skip that step)

* Following that with the *rorpi-readonly.sh* script, run as **bash rorpi-readonly.sh** will quickly perform the read only root installation on the SDCard.

If you use the above scripts, read the wiki notes at least once as they describe what's happening, or happened!


