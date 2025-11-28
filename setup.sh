#!/bin/bash
set -e

# Change this to your disk device
DISK="/dev/sda1"

echo "WARNING: This will erase all data on $DISK!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborting."
  exit 1
fi

echo "Creating GPT partition table on $DISK..."
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 boot on \
  mkpart primary ext4 513MiB 100%

echo "Formatting partitions..."
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"

echo "Mounting partitions..."
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot
mount "${DISK}p1" /mnt/boot

echo "Installing base system..."
pacstrap /mnt base linux linux-firmware

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Changing root into the new system..."
arch-chroot /mnt /bin/bash
