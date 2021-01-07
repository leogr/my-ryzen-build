#!/usr/bin/env bash
set -xeuo pipefail

USER=leogr
ROOT_DEV=/dev/nvme0n1p2
BOOT_LOADER_ENTRY=/boot/loader/entries/arch.conf
ECHO_PREFIX=">>> my-ryzen-build: "

# https://wiki.archlinux.org/index.php/Installation_guide

echo "$ECHO_PREFIX Configuring localtime"
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime 
hwclock --systohc

echo "$ECHO_PREFIX Locale gen"
locale-gen

echo "$ECHO_PREFIX Bootloader with microcode updates"
bootctl --path=/boot install

echo "$ECHO_PREFIX Bootloader entry"
echo "options cryptdevice=UUID=$(blkid -s UUID -o value $ROOT_DEV):lvm:allow-discards root=/dev/mapper/vg0-root rw" >> $BOOT_LOADER_ENTRY
cat $BOOT_LOADER_ENTRY

# NOT required:
# mkinitcpio -c /etc/mkinitcpio.conf -g /boot/initramfs-linux.img

echo "$ECHO_PREFIX Install packages (pkglist.txt)"
pacman -Syu archlinux-keyring
pacman -Syu - < /root/pkglist.txt

echo "$ECHO_PREFIX Setup root pass"
passwd

echo "$ECHO_PREFIX Add user ($USER)"
useradd -m -g users -G wheel -s /usr/bin/zsh $USER
passwd $USER
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\ALL\)/\1/' /etc/sudoers

echo "$ECHO_PREFIX Enable systemd services"
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable gdm

echo "$ECHO_PREFIX DONE!"