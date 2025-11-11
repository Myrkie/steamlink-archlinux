#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# === Constants (Do not change) ===
kernel_name="6.12.57-MYKERN-LTS-11-9"
temp_sysroot="/media/temp_sysroot_arch"
factory_test_folder="$temp_sysroot/steamlink/factory_test"
home_scripts_folder="$temp_sysroot/home/alarm/scripts"
packages=(tar e2fsprogs qemu-user-static coreutils util-linux mount)

# === Configurable ===
disk_label="ArchBtw"

# === Functions ===
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# shellcheck disable=SC2120
require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "Root privileges required. Re-running with sudo..."
        exec sudo "$0" "$@"
    fi
}

check_dependencies() {
    echo "Checking required packages..."
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            echo "$pkg already installed."
        else
            echo "Installing $pkg..."
            apt-get install -y "$pkg" >/dev/null || error_exit "Failed to install $pkg"
        fi
    done
}

format_device() {
    local dev="$1"
    echo "About to format $dev (ALL DATA WILL BE LOST)"
    read -rp "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || error_exit "Operation cancelled by user."

    umount "$dev" || true
    echo "[1/10] Formatting $dev..."
    mkfs.ext3 -v -L "$disk_label" "$dev" || error_exit "Formatting failed"
}

mount_device() {
    mkdir -p "$temp_sysroot"
    echo "[2/10] Mounting $1 to $temp_sysroot"
    mount "$1" "$temp_sysroot" || error_exit "Mount failed"
}

download_and_unpack() {
    echo "[3/10] Downloading Arch userspace..."
    local url="http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz"
    local tarfile="arch_userspace.tar.gz"
    curl -L -o "$tarfile" "$url" || error_exit "Download failed"
    echo "[3.5/10] Extracting..."
    tar --warning=no-unknown-keyword -xvpf "$tarfile" -C "$temp_sysroot" || error_exit "Extraction failed"
    rm "$tarfile"
}

copy_files() {
    echo "[4/10] Starting file copy stage..."
    echo "--------------------------------------------"
    echo "Target sysroot: $temp_sysroot"
    echo "Kernel version: $kernel_name"
    echo "--------------------------------------------"

    log_step() { echo "   → $1"; }
    ensure_file() { [[ -f "$1" ]] || error_exit "Missing required file: $1"; }
    ensure_dir()  { [[ -d "$1" ]] || error_exit "Missing required directory: $1"; }

    log_step "Copying kexec_load.ko to /boot"
    ensure_file kexec_load.ko
    cp kexec_load.ko "$temp_sysroot/boot/" || error_exit "Failed to copy kexec_load.ko"

    log_step "Copying kernel directory (mykern/) to /boot"
    ensure_dir mykern
    cp -r mykern/ "$temp_sysroot/boot/" || error_exit "Failed to copy kernel directory"

    log_step "Copying initramfs-linux.img to /boot"
    ensure_file initramfs-linux.img
    cp initramfs-linux.img "$temp_sysroot/boot/" || error_exit "Failed to copy initramfs"

    log_step "Copying mkinitcpio preset to /etc/mkinitcpio.d/"
    ensure_file linux-armv7-steamlink.preset
    mkdir -p "$temp_sysroot/etc/mkinitcpio.d/"
    cp linux-armv7-steamlink.preset "$temp_sysroot/etc/mkinitcpio.d/" || error_exit "Failed to copy preset"

    log_step "Copying kernel modules directory ($kernel_name) to /lib/modules/"
    ensure_dir "$kernel_name"
    cp -r "$kernel_name" "$temp_sysroot/lib/modules/" || error_exit "Failed to copy kernel modules"

    log_step "Copying kexec binary to /usr/bin and setting permissions"
    ensure_file kexec
    mkdir -p "$temp_sysroot/usr/bin/"
    cp kexec "$temp_sysroot/usr/bin/" || error_exit "Failed to copy kexec binary"
    chmod 755 "$temp_sysroot/usr/bin/kexec"

    log_step "Copying qemu-arm-static to /usr/bin and setting permissions"
    ensure_file /usr/bin/qemu-arm-static
    cp /usr/bin/qemu-arm-static "$temp_sysroot/usr/bin/" || error_exit "Failed to copy qemu-arm-static"
    chmod 755 "$temp_sysroot/usr/bin/qemu-arm-static"

    log_step "Copying factory test script (run.sh) to $factory_test_folder"
    ensure_file run.sh
    mkdir -p "$factory_test_folder/"
    cp run.sh "$factory_test_folder/" || error_exit "Failed to copy run.sh"
    chmod 755 "$factory_test_folder/run.sh"

    log_step "Creating SSH enable file"
    mkdir -p "$temp_sysroot/steamlink/config/system/"
    touch "$temp_sysroot/steamlink/config/system/enable_ssh.txt"

    log_step "Copying initialization scripts to $home_scripts_folder"
    ensure_dir scripts
    ensure_file scripts/initpacman.sh
    mkdir -p "$home_scripts_folder/"
    cp scripts/initpacman.sh "$home_scripts_folder/" || error_exit "Failed to copy initpacman.sh"
    chmod +x "$home_scripts_folder/initpacman.sh"
    chmod 755 "$home_scripts_folder/"

    echo "--------------------------------------------"
    echo "File copy stage complete. All files copied successfully."
    echo "--------------------------------------------"
}


run_chroot() {
    echo "[10/10] Chrooting into environment..."
    chroot "$temp_sysroot" /usr/bin/qemu-arm-static /bin/bash -lc "/home/alarm/scripts/initpacman.sh"
}

cleanup() {
    echo "Completed, unmounting disk. This may take a while."
    umount -l "$1" || error_exit "Unmount failed"
    rm -rf "$temp_sysroot"
    sync
}

# === Main ===
echo "ArchLinux BootMedium Creator for Steamlink"
echo "Based on: https://www.reddit.com/r/Steam_Link/comments/fgew5x/running_archlinux_on_steam_link_revisited/"
echo "Created by Regmibijay, Myrkur"

require_root
check_dependencies

blkid
echo
read -rp "Enter device path (e.g., /dev/sdb1): " devaddress
[[ -b "$devaddress" ]] || error_exit "Invalid device: $devaddress"

format_device "$devaddress"
mount_device "$devaddress"
download_and_unpack
copy_files
run_chroot

echo -e "At this stage you can make any last minute changes to the media at $temp_sysroot"
read -rp "Press Enter to unmount and finish."
cleanup "$devaddress"

echo  "Completed. Please remove the USB disk and insert it into the steamlink."