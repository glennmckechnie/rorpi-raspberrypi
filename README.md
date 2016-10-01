# rorpi - raspberrypi
A method to run a Raspberry Pi, using the Raspbian distribution, configured with a read only / file system  - thus the name "Read Only Root Pi" or RORPi

It should then be able to run the Weewx weather station software ( http://weewx.com ) with the minimum of upkeep. It's not limited to weewx either, it should also be re-configurable for anything else that fits the same criteria.

Like any system that holds valuable information, it will require the addition of a suitable back-up routine.  That's not part of this HowTo and will need to be configured for your needs anyway.


Visit the wiki for greater detail -
https://github.com/glennmckechnie/rorpi-raspberrypi/wiki/Rorpi-Home

For discussion, visit the google group at
https://groups.google.com/forum/#!forum/rorpi-discussion

Update:- 1st October 2016

Scripts have been added (in the helper-scripts directory), along with a gzipped tarball (in the main directory) of the required files and directories. This is to preserve ownership and permissions of the required files, and as it turns out helps in the automation of the read-only installation process.

rorpi-script.sh has been contributed by ssinfod. It can be run to automatically download that compressed file, unpack its contents accordingly and perform the necessary actions to turn the system into a read-only one.

sdcard_write_read_confirm.sh is a script to help with the transfer of the initial raspbian image to the SDCard, when running under Linux.
