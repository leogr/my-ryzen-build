#!/usr/bin/env bash
set -xeuo pipefail

BOOT_DEV=/dev/nvme0n1p1
ROOT_DEV=/dev/nvme0n1p2

# Format the root partition
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

# Format the EFI partition
mkfs.fat ${BOOT_DEV}

# Mount shared EFI
mkdir /mnt/boot
mount ${BOOT_DEV} /mnt/boot

# Install the base packages, firmware, and drivers
pacstrap /mnt base base-devel linux linux-firmware linux-headers \
    amd-ucode efibootmgr mkinitcpio \
    mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau libva-vdpau-driver

# Generate fstab and chroot into /mnt
genfstab -pU /mnt >> /mnt/etc/fstab

# Copy /boot
cp -R ./boot /mnt/boot

# Copy /etc
cp -R ./etc /mnt/etc

# Chroot setup
cp ./chroot_setup.sh /mnt/root/chroot_setup.sh
cp ./pkglist.txt /mnt/root/pkglist.txt
arch-chroot /mnt /root/chroot_setup.sh

# Clenaup
rm -rf /mnt/root/chroot_setup.sh
rm -rf /mnt/root/pkglist.txt