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

for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed."
    else
        echo "$pkg is not installed. Installing..."
        sudo apt-get install -y "$pkg"
    fi
done

echo ""
sudo blkid
echo ""
echo "Please enter /dev/ address of your USB disk from above."
echo "For example /dev/sdb1"
echo "CAUTION! That device will be formatted and you will lose any data in there!"

read -r devaddress
sudo umount "$devaddress"
echo [1/10] formatting "$devaddress"
sudo mkfs.ext3 -v -L "$disk_label" "$devaddress"
echo [2/10] mounting "$devaddress" to $temp_sysroot
sudo mkdir -p $temp_sysroot/
sudo mount "$devaddress" $temp_sysroot
echo [3/10] "Downloading and unpacking userspace to $temp_sysroot"
curl -Lo arch_userspace.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
sudo tar --warning=no-unknown-keyword -xvpf arch_userspace.tar.gz -C $temp_sysroot/
echo [4/10] "Copying kexec_load.ko"
sudo cp kexec_load.ko $temp_sysroot/boot/
echo [5/10] "Copying kernel"
sudo cp -r mykern/ $temp_sysroot/boot/
sudo cp initramfs-linux.img $temp_sysroot/boot/
sudo cp linux-armv7-steamlink.preset $temp_sysroot/etc/mkinitcpio.d/
echo [6/10] "Copying kexec and 755 on kexec"
sudo cp kexec $temp_sysroot/usr/bin
sudo chmod 755 $temp_sysroot/usr/bin/kexec
echo [7/10] "Copying kernel modules to modules"
sudo cp -r $kernel_name/ $temp_sysroot/lib/modules/
echo [8/10] "Copying qemu arm static binary"
sudo cp /usr/bin/qemu-arm-static $temp_sysroot/usr/bin
sudo chmod 755 $temp_sysroot/usr/bin/qemu-arm-static
echo [9/10] "Copying run.sh and 755 on it"
sudo mkdir -p $factory_test_folder/
sudo cp run.sh $factory_test_folder/
sudo chmod 755 $factory_test_folder/run.sh
echo [9.8/10] "Finally creating ssh folder"
sudo mkdir -p $temp_sysroot/steamlink/config/system/
sudo touch $temp_sysroot/steamlink/config/system/enable_ssh.txt
echo [9.9/10] "Copying init script to home/scripts"
sudo mkdir $home_scripts_folder/
sudo cp scripts/initpacman.sh $home_scripts_folder
sudo chmod +x $home_scripts_folder/initpacman.sh
sudo chmod 755 $home_scripts_folder/
echo [10/10] "Chrooting into directory"
sudo chroot $temp_sysroot/ qemu-arm-static bin/bash -lc "/home/alarm/scripts/initpacman.sh;"
read -rp "Press Enter to continue and unmount."
echo "Completed, unmounting disk. This may take a while."
sudo umount -l "$devaddress"
echo "Cleaning up ... "
sudo rm -rf $temp_sysroot
sudo sync
echo  "Completed. Please remove the USB disk and insert it into steamlink."
