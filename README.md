setup-autofs
============

Script to help set-up `autofs` on Mac OS X. This script creates a new folder at `/mnt/` and maps SMB shared volumes to that folder.

1. Copy the `setup-autofs.pl` script into your Desktop folder.
2. Customise the script to provide your SMB details.
3. Launch Terminal.app from the Applications > Utilities folder.
4. Issue the following command in Terminal.app:

	`sudo ~/Desktop/setup-autofs.pl`

5. You will be immediately asked for your administrator password. This is needed to modify and create the following files:

	* /etc/auto\_master
	* /etc/auto\_mnt

This script has been tested on Mac OS X 10.9.