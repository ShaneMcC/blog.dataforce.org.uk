#!/bin/bash

set -e

# Install Required Packages
apt-get update
apt-get -y install grub-pc linux-image-generic arch-install-scripts parted

# Configure the secondary disk - grub partition at the start, swap for the rest.
parted /dev/sdb --script mktable gpt
parted /dev/sdb --script disk_set pmbr_boot on
parted /dev/sdb --script mkpart grub 0 2047s
parted /dev/sdb --script set 1 bios_grub on
parted /dev/sdb --script mkpart swap 2048s 100%

# Turn on the swap so that we can generate /etc/fstab correctly
mkswap /dev/sdb2
swapon /dev/sdb2

# Change the kernel boot params so that we can see it booting
# and also to use the older device names as that's what they were named like in LXC so all our configuration expects that
sed -i 's/quiet splash//' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' /etc/default/grub

# Generate a basic fstab for our disk and swap
genfstab -t UUID / > /etc/fstab
blkid | grep /dev/sd | sed -r 's/:.* (UUID=[^ ]*).*/;\1/' | while read re; do sed -i "s;^$re;;" /etc/fstab; done

# Prepare and Install and grub
update-initramfs -k all -c
update-grub
grub-install --target=i386-pc --boot-directory=/boot --disk-module=biosdisk /dev/sdb
update-grub
exit
