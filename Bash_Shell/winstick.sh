#/bin/sh

DEV="/dev/sda"
DEV_BOOT="$DEV"1
DEV_INSTALL="$DEV"2
ISO="Win11_24H2_German_x64.iso"
ISO_PATH="/home/diam0rphine/Downloads"

#  Format your USB flash drive
wipefs -a $DEV
parted $DEV mklabel gpt                     
parted $DEV mkpart BOOT fat32 0% 1GiB
parted $DEV mkpart INSTALL ntfs 1GiB 10GiB

# Check the drive layout now:
parted $DEV unit B print

# Mount Windows ISO
mkdir /mnt/iso
mount $ISO_PATH/$ISO /mnt/iso/

# Format 1st partition of your USB flash drive as FAT32
mkfs.vfat -n BOOT $DEV_BOOT
mkdir /mnt/vfat
mount $DEV_BOOT /mnt/vfat/

# Copy everything from Windows ISO image except for the sources directory there
rsync -r --progress --exclude sources --delete-before /mnt/iso/ /mnt/vfat/

# Copy only boot.wim file from the sources directory, while keeping the same path layout
mkdir /mnt/vfat/sources
cp /mnt/iso/sources/boot.wim /mnt/vfat/sources/

# Format 2nd partition of your USB flash drive as NTFS
mkfs.ntfs --quick -L INSTALL $DEV_INSTALL
mkdir /mnt/ntfs
mount $DEV_INSTALL /mnt/ntfs

# Copy everything from Windows ISO image there
rsync -r --progress --delete-before /mnt/iso/ /mnt/ntfs/

# Unmount the USB flash drive and Windows ISO image
umount /mnt/ntfs
umount /mnt/vfat
umount /mnt/iso
sync

# Power off your USB flash drive
udisksctl power-off -b $DEV
