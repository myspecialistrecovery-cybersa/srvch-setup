#!/bin/bash
set -e

# Variables - customize these!
HOSTNAME="myarch"
TIMEZONE="Europe/Oslo"
LOCALE="en_US.UTF-8"
USERNAME="user"
ROOT_PASSWORD="rootpassword"
USER_PASSWORD="userpassword"
ROOT_PART="/dev/mmcblk0p2"  # Change if your root partition is different

echo "Setting timezone..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "Configuring locales..."
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

echo "Setting hostname..."
echo $HOSTNAME > /etc/hostname

echo "Configuring /etc/hosts..."
cat > /etc/hosts <<EOF
127.0.0.1	localhost
::1		    localhost
127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME
EOF

echo "Setting root password..."
echo "root:$ROOT_PASSWORD" | chpasswd

echo "Installing essential packages..."
pacman -Syu --noconfirm networkmanager sudo nano

echo "Enabling NetworkManager service..."
systemctl enable NetworkManager

echo "Installing bootloader (systemd-boot)..."
bootctl install

PARTUUID=$(blkid -s PARTUUID -o value $ROOT_PART)

echo "Creating bootloader entry..."
mkdir -p /boot/loader/entries
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$PARTUUID rw
EOF

echo "Creating loader.conf..."
cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
editor 0
EOF

echo "Creating user $USERNAME..."
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd

echo "Configuring sudoers for wheel group..."
sed -i 's/^# \(%wheel ALL=(ALL) ALL\)/\1/' /etc/sudoers

echo "Installing Xorg, XFCE and LightDM..."
pacman -S --noconfirm xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter

echo "Enabling LightDM..."
systemctl enable lightdm

echo "Setting graphical target as default..."
systemctl set-default graphical.target

echo "Setup complete! You can now exit and reboot."
