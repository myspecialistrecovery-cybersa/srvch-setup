#!/bin/bash

set -e

# Variables - customize these!
HOSTNAME="myarch"
TIMEZONE="Europe/Oslo"
LOCALE="en_US.UTF-8"
KEYMAP="us"
ROOT_PASSWORD="rootpassword"     # Change this or prompt later

# 1. Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# 2. Localization
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# 3. Hostname
echo $HOSTNAME > /etc/hostname

# 4. Hosts file
cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# 5. Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# 6. Install essential packages
pacman -Syu --noconfirm networkmanager sudo nano

# 7. Enable NetworkManager
systemctl enable NetworkManager

# 8. Install bootloader (systemd-boot)
bootctl install

# Get PARTUUID of root partition
ROOT_PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) # Change /dev/sda2 accordingly

mkdir -p /boot/loader/entries
cat << EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$ROOT_PARTUUID rw
EOF

# 9. Install Xorg and XFCE desktop environment + LightDM
pacman -S --noconfirm xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter

# Enable LightDM
systemctl enable lightdm

# 10. Set default target to graphical
systemctl set-default graphical.target

echo "Setup complete! Exit chroot and reboot."
