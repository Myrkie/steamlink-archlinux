# steamlink-archlinux
Create Archlinux boot medium for steamlink with one script!
Archlinux with linux 6.12.57 LTS (Kernel can be updated inside arch once you flash it.)

## Steps

Download or git clone this project to a linux machine.

Run `boot_device_creator.sh` from bash (terminal) 

Be careful while specifying device addresses as the script WILL wipe all data of that device. Any data lost or any harm done is your own responsibility.

Run `pacman -Syu` and `mkinitcpio -P` manually on bare metal, not within the Chroot environment

## Default hostname as defined by kernal compile:
Hostname: `steamlink.internal`

## Default passwords:

### Default user
User: `alarm`
password: `alarm`

### Root user
User: `root`
password: `root`


## Misc
Based on  https://www.reddit.com/r/Steam_Link/comments/fgew5x/running_archlinux_on_steam_link_revisited/
