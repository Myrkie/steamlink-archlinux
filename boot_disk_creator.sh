#!/bin/bash
echo "ArchLinux BootMedium Creator for Steamlink"
echo "Based on https://www.reddit.com/r/Steam_Link/comments/fgew5x/running_archlinux_on_steam_link_revisited/"
echo "Installing qemu user static binaries"
sudo apt-get install qemu-user-static
echo ""
sudo blkid
echo ""
echo "Please enter /dev/ address of your USB disk from above."
echo "For example /dev/sdb1"
echo "CAUTION! That device will be formatted and you will lose any data in there!"
kernel_name="6.12.57-MYKERN-LTS-11-9"
temp_dir="/media/disk"
read -r devaddress
sudo umount "$devaddress"
echo [1/10] formatting "$devaddress"
sudo mkfs.ext3 -v -L "ArchBtw" "$devaddress"
echo [2/10] mounting "$devaddress" to $temp_dir
sudo mkdir -p $temp_dir/
sudo mount "$devaddress" $temp_dir
echo [3/10] "Downloading and unpacking userspace to $temp_dir"
curl -Lo arch_userspace.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
sudo tar -xvpf arch_userspace.tar.gz -C $temp_dir/
echo [4/10] "Copying kexec_load.ko"
sudo cp kexec_load.ko $temp_dir/boot/
echo [5/10] "Copying kernel"
sudo cp -r mykern/ $temp_dir/boot/
sudo cp linux-armv7.preset $temp_dir/etc/mkinitcpio.d/
echo [6/10] "Copying  kexec and 755 on kexec"
sudo cp kexec $temp_dir/usr/bin
sudo chmod 755 $temp_dir/usr/bin/kexec
echo [7/10] "Copying kernel modules to modules"
sudo cp -r $kernel_name/ $temp_dir/lib/modules/
echo [8/10] "Copying qemu arm static binary"
sudo cp /usr/bin/qemu-arm-static $temp_dir/usr/bin
sudo chmod 755 $temp_dir/usr/bin/qemu-arm-static
echo [9/10] "Copying run.sh and 755 on it"
sudo mkdir -p $temp_dir/steamlink/factory_test/
sudo cp run.sh $temp_dir/steamlink/factory_test/
sudo chmod 755 $temp_dir/steamlink/factory_test/run.sh
echo [9.8/10] "Finally creating ssh folder"
sudo mkdir -p $temp_dir/steamlink/config/system/
sudo touch $temp_dir/steamlink/config/system/enable_ssh.txt
echo [10/10] "Chrooting into directory"
sudo chroot $temp_dir/ qemu-arm-static bin/bash
read -rp "Press Enter to continue and unmount."
echo "Completed, unmounting disk. This may take a while."
sudo umount -l "$devaddress"
echo "Cleaning up ... "
sudo rm -rf $temp_dir
sudo sync
echo  "Completed. Please remove the USB disk and insert it into steamlink."
