---
title: "Converting LXC Containers to full VMs"
author: Dataforce
url:  /2024/11/convert-lxc-container-to-vm/
image: convertlxctovm.png
description: Converting LXC Containers to full VMs
type: post
date: 2024-11-23T02:10:31Z
category:
  - General
  - Proxmox
---

I have been a long-time user of [proxmox](https://www.proxmox.com/en/) for my virtualisation needs, starting back in the days of Proxmox 3 (prior to that I was running Ubuntu with OpenVZ rolled in by hand). Back then I only had a single server and resources were tight, so I deployed a lot of my workloads as OpenVZ containers.

As time went on, proxmox switched to LXC, and I dutifully converted all my containers to LXC and kept on going.

More time went on and I added more servers, and ended up clustering them for ease of management. Then eventually replacing them all with more powerful nodes so now resources were no longer a concern. I also eventually added Ceph into the mix (using proxmox's built-in support for ceph) and 10G Networking so that I had shared storage for VMs and could the start doing VM migrations between nodes quickly.

But, LXC Conainers have flaws - live migration only works for full-VMs. LXC Containers have to do a reboot to actually move onto and start running on the new node. For some workloads this isn't really noticable or a problem - but for others this is quite bad.

Also, as more and more of what I run involves Docker, it's a lot easier/nicer/safer to run these workloads in actual VMs rather than LXC containers.

But installing and configuring full-VMs was a chore. With LXC Containers you could be up and running in minutes by just deploying a template. Full-VMs required a full installation to an empty disk. This could be automated using kickstart/preseeding etc (And I wrote [a tool](https://github.com/ShaneMcC/PXE-Manager) to help manage a pxe-boot environments for this purpose). But over time, this has now become trivial as well - cloud-init is now supported directly within proxmox and all the major OSes provide cloud-init compatible disk images, so getting a fresh VM is a matter of cloning a template, updating some cloud-init settings and starting the VM.

Due to all of this, almost all of the VMs I create these days are full VMs. Anything new - it's a VM, which gives me all-the-good-stuff™.

But I still have a lot of legacy LXC containers. These all end up suffering any time I do hardware/software maintenance on the host nodes, or if I have any problems that require putting a host into maintenance mode.

<br>

It's time to fix this.

<br>

<!--more-->

With this in mind, I recently started a process of switching some of these into full VMs. Now, this is not a new thing that people want to do, and infact there are a [few](https://forum.proxmox.com/threads/convert-proxmox-lxc-to-a-regular-vm.141687/) [posts](https://forum.proxmox.com/threads/migrate-lxc-to-kvm.56298/) around the proxmox forums of people wanting to do this, but the answer is almost always the same. "No, you can't just convert them" or "yes, but it's a lot of work".

<br>

So initially I just started by doing full re-deploys of VMs that were trivial (either only running docker containers, or entirely deployed using ansible), and then by doing some of the more-complex ones by hand using the long-and-convoluted processes (deploying a new vm, copying all the data across, etc).

It was as I was doing one of these more-complex ones, I got to thinking. In days-of-olde, containers were glorified chroots, just using a directory on the host file system for their own file system. But things are a lot different now, these days the containers use filesystem image files or block-devices for their disk... in much the same way as a full VM does.

So this made me wonder, could I just... attach one of these to a VM, and boot from it?

Well no. not quite.

<br>

Unlike full VMs where the disk image is a full disk, with a partition table and partitions, the containers are just a single filesystem. So no bootloader.

In addition, most of the container images are missing a whole bunch of packages needed to actually function on their own (they rely on the host OS for these) such as a kernel.

But, if we could install these packages, and provide space for a bootloader - what about then?

Turns out - yes.

<br>

> **Disclaimer**
>
> I take no responsibility for any data loss that may occur from trying to follow this process, make sure you have suitable backups of any VMs that you attempt to convert. It's best to convert using a disk clone rather than risking your only copy of the source VM.
>
> In addition, all my LXC Containers are running ubuntu, so these instructions are written with that in mind.
>
> All the VMs I've converted with this process are working fine after the conversion so far, but none of them have been running for long enough post-conversion to ensure the long-term viability of these conversions.


#### VM Prep Work:

To get started, we need to create a fresh VM that we will use for the converted container.

  - Create a new VM of the desired spec, with no disks attached.
    - I am assuming you are using VirtIO SCSI for the disk controller.
  - Add (a copy of) the old disk image as `scsi0` (This is generally an exercise left to the reader, there are too many different ways to do this)
    - Something like `rbd -p data_data mv vm-1234-disk-0 vm-5678-disk-0; echo "scsi0: ceph:vm-5678-disk-0" >> /etc/pve/qemu-server/5678.conf` may work.
  - Add a new blank drive for your swap partition and bootloader as `scsi1`
      - If you want to have no swap, then create as small a disk as possible - you just need somewhere to put a grub bootloader which is ~1mb
  - Set the boot order in proxmox to `scsi1` then `scsi0`
    - This is important, during the boot process it seems that grub can only see the `scsi0` disk not any others (it can see SATA disks but only the first SCSI one.)
    - However, we can't install grub onto this disk as it is not partitioned so there is no space for it, so grub ends up on `scsi1` which is why we put that first in the boot order.
    - Setting the boot order this way means that we load grub from `scsi1`, but then grub is able to find all the data it needs on `scsi0`
      - In theory, we could create a new large disk, partition it, `dd` the old disk into a new partition and just have a single disk and not worry about any of this - but that long process is what we're trying to avoid here.
  - Add a cloud-init disk with at least a username/ssh-key and generate the image.
    - You can put networking config there, but it will be unused in this process.

#### Live-Boot environment

Originally this guide suggested using an ubuntu live-server installer ISO, but this didn't bring up netowrking correctly and required a bunch of extra steps, however I have since discovered that SolusVM provide instructions on creating a [solusvm rescue image](https://support.solusvm.com/hc/en-us/articles/21335522896919-How-to-create-custom-bootable-rescue-ISO-image-with-Ubuntu-22-for-SolusVM-2) iso that works exactly as we need.

Download the ISO from [https://images.prod.solus.io/rescue/rescue-latest.iso](https://images.prod.solus.io/rescue/rescue-latest.iso) and use that as a cd image on the VM to do a one-time-boot.

Once it has booted, you can SSH into the VM using the IP/User details from the cloud-init image.

Once in a shell, you can run the following commands to jump into a working chroot of the disk image:
```bash
mount /dev/sda /mnt
for F in /dev /sys /dev/pts /proc; do mount -o bind {,/mnt}${F}; done
chroot /mnt
```

#### Actual Conversion

Once inside the chroot, you can now do the following to install and configure the required packages and files:

```shell
# Install Required Packages
apt-get update
apt-get -y install grub-pc linux-image-generic arch-install-scripts parted qemu-guest-agent

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
```
(This is available as a [script](convert_script.sh) that I take no responsibility for, if your vm setup is not correct this may blat all your data.)

This is everything done, so now you can unmount everything and reboot:
```shell
for F in /dev/pts; do umount /mnt${F}; sleep 5; done
for F in /dev /sys /proc; do umount /mnt${F}; done
umount /mnt
reboot
```
(This whole process is also available as a [script](outer_script.sh) that I take no responsibility for, if your vm setup is not correct this may blat all your data.)

You will need to go back to the console of the VM and press enter to *actually* reboot as it waits for you to confirm that you have ejected the CD.

If everything has gone right, the VM should now just boot up and work, and now you can get the benefits of having full VMs rather than just containers.
