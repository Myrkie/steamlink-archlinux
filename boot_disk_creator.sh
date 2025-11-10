#!/bin/bash
# Do not change
kernel_name="6.12.57-MYKERN-LTS-11-9"
temp_sysroot="/media/temp_sysroot_arch"
factory_test_folder="$temp_sysroot/steamlink/factory_test"
home_scripts_folder="$temp_sysroot/home/alarm/scripts"
packages=("tar" "e2fsprogs" "qemu-user-static" "coreutils" "util-linux" "mount")
# changeable
disk_label="ArchBtw"

echo "ArchLinux BootMedium Creator for Steamlink"
echo "Based on https://www.reddit.com/r/Steam_Link/comments/fgew5x/running_archlinux_on_steam_link_revisited/"
echo "Checking required packages"

# elevate 
if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed."
    else
        echo "$pkg is not installed. Installing..."
        apt-get install -y "$pkg"
    fi
done

echo ""
blkid
echo ""
echo "Please enter /dev/ address of your USB disk from above."
echo "For example /dev/sdb1"
echo "CAUTION! That device will be formatted and you will lose any data in there!"

read -r devaddress
umount "$devaddress"
echo [1/10] formatting "$devaddress"
mkfs.ext3 -v -L "$disk_label" "$devaddress"
echo [2/10] mounting "$devaddress" to $temp_sysroot
mkdir -p $temp_sysroot/
mount "$devaddress" $temp_sysroot
echo [3/10] "Downloading and unpacking userspace to $temp_sysroot"
curl -Lo arch_userspace.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
tar --warning=no-unknown-keyword -xvpf arch_userspace.tar.gz -C $temp_sysroot/
echo [4/10] "Copying kexec_load.ko"
cp kexec_load.ko $temp_sysroot/boot/
echo [5/10] "Copying kernel"
cp -r mykern/ $temp_sysroot/boot/
cp initramfs-linux.img $temp_sysroot/boot/
cp linux-armv7-steamlink.preset $temp_sysroot/etc/mkinitcpio.d/
echo [6/10] "Copying kexec and 755 on kexec"
cp kexec $temp_sysroot/usr/bin
chmod 755 $temp_sysroot/usr/bin/kexec
echo [7/10] "Copying kernel modules to modules"
cp -r $kernel_name/ $temp_sysroot/lib/modules/
echo [8/10] "Copying qemu arm static binary"
cp /usr/bin/qemu-arm-static $temp_sysroot/usr/bin
chmod 755 $temp_sysroot/usr/bin/qemu-arm-static
echo [9/10] "Copying run.sh and 755 on it"
mkdir -p $factory_test_folder/
cp run.sh $factory_test_folder/
chmod 755 $factory_test_folder/run.sh
echo [9.8/10] "Finally creating ssh folder"
mkdir -p $temp_sysroot/steamlink/config/system/
touch $temp_sysroot/steamlink/config/system/enable_ssh.txt
echo [9.9/10] "Copying init script to home/scripts"
mkdir $home_scripts_folder/
cp scripts/initpacman.sh $home_scripts_folder
chmod +x $home_scripts_folder/initpacman.sh
chmod 755 $home_scripts_folder/
echo [10/10] "Chrooting into directory"
chroot $temp_sysroot/ qemu-arm-static bin/bash -lc "/home/alarm/scripts/initpacman.sh;"
echo -e "at this stage you can make any last minute changes to the media at $temp_sysroot"
read -r "Press Enter to continue and unmount"
echo "Completed, unmounting disk. This may take a while."
umount -l "$devaddress"
echo "Cleaning up ... "
rm -rf $temp_sysroot
sync
echo  "Completed. Please remove the USB disk and insert it into steamlink."
