#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2120
require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "Root privileges required. Re-running with sudo..."
        exec sudo "$0" "$@"
    fi
}

init_pacman(){
    echo "Initializing pacman keys"
    pacman-key --init
    pacman-key --populate archlinuxarm
}



require_root
init_pacman

echo "Init complete you can now exit chroot, or install additional packages now."
echo "You will have to run (pacman -Syu) and (mkinitcpio -P) manually on bare metal"

rm -- "$0"