# rorpi - raspberrypi
A method to run a Raspberry Pi, using the Raspbian distribution, configured with a read only / file system  - thus the name "Read Only Root Pi" or RORPi

It should then be able to run the Weewx weather station software ( http://weewx.com ) with the minimum of upkeep. It's not limited to weewx either, it should also be re-configurable for anything else that fits the same criteria.

Like any system that holds valuable information, it will require the addition of a suitable back-up routine.  That's not part of this HowTo and will need to be configured for your needs anyway.


### Visit the wiki for greater detail -
https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/Rorpi-Home

### For discussion, visit the google group at -
https://groups.google.com/forum/#!forum/rorpi-discussion

## Updates:
* 1st October 2016

Scripts have been added (in the helper-scripts directory), along with a gzipped tarball (in the main directory) of the required files and directories. This is to preserve ownership and permissions of the required files, and as it turns out helps in the automation of the read-only installation process.

The script *rorpi-readonly.sh* has been contributed by ssinfod. It can be run to automatically download that compressed file, unpack its contents accordingly and perform the necessary actions to turn the system into a read-only one. As its name suggests **bash rorpi-readonly.sh** performs the tasks on the readonly wiki page.
https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-readonly

* 6th October 2016

Within the helper-scripts directory, another script (rorpi-preinstall.sh) has been added to perform the actions of the preinstall wiki page.  https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/rorpi-raspberrypi-preinstall
In addition there is also a script *sdcard_write_read_confirm.sh* to help with the initial image transfer described on that page.

Running *sdcard_write_read_confirm.sh* will assist with the image transfer to the SDCard (providing you are on a Linux machine). Or you can follow the manual instructions available where you got the image. **bash sdcard_write_read_confirm.sh** will display usage notes.

Running *rorpi-preinstall.sh* will give you an updated version of Raspian with the added bonus of a Weewx install. (You can edit that script and perform an automatic apt-get install, effectively answering yes to all questions, by changing  *apt_optn=""* to *apt_optn="-y"*  The script also accepts the option 'noweewx' - **bash rorpi-preinstall.sh noweewx** - if you wish to skip that step)

Following that with the *rorpi-readonly.sh* script will quickly perform the read only root installation on the SDCard.

If you use the above scripts, read the wiki notes at least once as they describe what's happening, or happened!


