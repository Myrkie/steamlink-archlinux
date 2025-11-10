#!/bin/bash

echo "Initializing pacman keys"
su -c "pacman-key --init"
su -c "pacman-key --populate archlinuxarm"

while true; do
    read -rp "Do you want to remove the preinstalled ARCH kernel? (y/n) " yn
    case $yn in
        [Yy]* ) 
            echo "Proceeding..."
            su -c "pacman -R linux-armv7"
            break
            ;;
        [Nn]* ) 
            echo "Keeping the kernel."
            break
            ;;
        * ) echo "Invalid response. Please answer y or n.";;
    esac
done
