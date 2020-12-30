#!/usr/bin/env bash
set -xeuo pipefail

BOOT_DEV ?= /dev/nvme0n1p1
ROOT_DEV ?= /dev/nvme0n1p2

# Format the underlying partition
mkfs.ext2 ${ROOT_DEV}

# Setup the encryption of the system
cryptsetup -c aes-xts-plain64 -y --use-random luksFormat ${ROOT_DEV}
cryptsetup luksOpen ${ROOT_DEV} luks

# Create the root encrypted partition
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate -l +100%FREE vg0 --name root

# Create filesystem on encrypted partition
mkfs.ext4 /dev/mapper/vg0-root

# Mount root filesystem
mount /dev/mapper/vg0-root /mnt

# Mount shared EFI
mkdir /mnt/boot
mount ${BOOT_DEV} /mnt/boot

# Install the base packages, firmware, and drivers
pacstrap /mnt base base-devel linux linux-firmware linux-headers \
    amd-ucode efibootmgr mkinitcpio \
    mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau libva-vdpau-driver \ 
    man htop radeontop zsh git

# Generate fstab and chroot into /mnt
genfstab -pU /mnt >> /mnt/etc/fstab

# todo(leogr): copy files to /mnt/root 
# cp -R ../ /mnt/root/

# todo(leogr): run the root script
arch-chroot /mnt
