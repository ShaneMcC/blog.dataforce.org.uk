---
title: PXE Goodness
author: Dataforce
type: post
date: 2008-06-10T01:52:22+00:00
url: /2008/06/PXE-Goodness/
category:
  - General

---
So as you may or may not know from time to time I have the joy of fixing computers for various people. A lot of these fixes result in a reinstall of windows and away.

This is a rather easy enough job, I have a KVM switch that I attach to the machine, pop a windows CD in (I used to have an unattended CD but don't any more), answer a few questions and then occasionally switch the KVM over to see if the install died or so.

Now this is all well and good except for 2 problems:

  1. It means I need to keep (or remember to bring) windows CDs at home (where I do most of my jobs)
  2. I recently had a machine to fix that had a non-working CD Drive

Now, the first one isn't so much of a problem, but the second one was.

So for some reason known only to him, my dad a while ago decided to invest in an External CD Writer rather than an internal one, so I do have a USB cd drive.

First port of call was to attach the CD Drive, pop in the CD, reboot the machine, tell it to boot from usb... oh, it doesn't recognise the drive. bugger.

So I googled a bit, There was lots of suggestions mostly to use a floppy disk with the USB drivers to bootstrap the install (no thanks, I doubt I 6 (yes, SIX!) working floppies required to bootstrap the windows installer).

Then I remembered ages ago when I was making my unattended CD, I discovered an app called (shockingly) "unattended" ([link](http://unattended.sourceforge.net/)) so I updated the copy of unattended I had on my server and went to investigate how to use it

The main suggested methods:

1. Burn a CD
2. Create a boot floopy

Neither of these were appealing (Floppies suck, I probably don't have a spare floppy anywhere that works) and the reason I was even looking at this was because the machine had no CD Drive.

However there was an alternative, network booting. Quickly check the back of the laptop, bingo! a network port!

So, I quickly (I say quickly, but my server was still Redhat 9 at the time, so rather slowly and painfully) I installed the tftp server (`apt-get install tftp-hda` on Ubuntu), configured xinet.d (see below) and my dhcp server (see below).

xinet.d/tftp:

{{< prettify shell >}}
# default: off
# description: The tftp server serves files using the trivial file transfer \
#       protocol.  The tftp protocol is often used to boot diskless \
#       workstations, download configuration files to network-aware printers, \
#       and to start the installation process for some operating systems.
service tftp
{
        socket_type             = dgram
        port                    = 69
        protocol                = udp
        wait                    = yes
        user                    = root
        server                  = /usr/sbin/in.tftpd
        server_args             = -s /tftpboot
        disable                 = no
        per_source              = 11
        cps                     = 100 2
        flags                   = IPv4
}
{{< /prettify >}}

dhcpd.conf:

{{< prettify shell >}}
# Not sure if this is needed, I added it anyway
allow bootp;
# My Servers IP
next-server 192.168.0.5;
# PXE Boot
filename "pxelinux.0";
{{< /prettify >}}

pxelinux.0 and its config directory can be found in bootdisk/tftpboot in the unattended distribution.

I also configured my internal DNS server as required by unattended to provide the ntinstall host.

This allowed me to boot up the machine using the network and install windows as normal (There are a few issues with this, namely that the windows XP installer sucks and requires a FAT32 partition for swap space, so you can't use unattended to upgrade an existing NTFS install, it has to format the drive as FAT32, install, convert it to NTFS, and defrag it)

This made me quite pleased, I copied my windows disks into the install/os directory, and my office disk into the appropriate directory (see the unattended site for all related configuration etc) and left it be.

A few days later I after I restarded one of my machines, it managed to network boot itself into the unattended menu rather than the hard disk, I quickly googled to find out how to make it boot its main hard drive, it gets IP 192.168.0.10, so I created `/tftpboot/pxelinux.cfg/C0A8000A` with the contents:

{{< prettify shell >}}
default local
label local
localboot 0
{{< /prettify >}}

This then prompted me to look at the pxelinux config a bit more, Wouldn't it be awesome to be able to install ubuntu OR windows using network boot? Yes, it would. I also threw in network boot support for DBAN aswell.

my `/tftpboot/pxelinux.cfg/default` now looks something like this:

{{< prettify shell >}}
DEFAULT menu.c32
PROMPT 0

MENU TITLE Network Boot Options

LABEL disk
        MENU LABEL ^Local Disk Boot
        MENU DEFAULT
        LOCALBOOT 0

LABEL unattended
        MENU LABEL ^Unattended Windows Install
        KERNEL /unattended/bzImage
        APPEND initrd=unattended/initrd

LABEL autonuke
        MENU LABEL DBAN ^Autonuke
        KERNEL /dban/kernel.bzi
        APPEND initrd=dban/initrd.gz root=/dev/ram0 init=/rc nuke="dwipe --autonuke" silent

LABEL dban
        MENU LABEL ^DBAN normal
        KERNEL /dban/kernel.bzi
        APPEND initrd=dban/initrd.gz root=/dev/ram0 init=/rc nuke="dwipe" silent

MENU SEPARATOR

LABEL -32
        MENU LABEL Ubuntu i386:
        MENU DISABLE

LABEL 32install
        MENU LABEL Ubuntu i386 Install
        MENU INDENT 1
        KERNEL ubuntu-installer/i386/linux
        APPEND vga=normal initrd=ubuntu-installer/i386/initrd.gz --

LABEL 32cli
        MENU LABEL Ubuntu i386 CLI
        MENU INDENT 1
        KERNEL ubuntu-installer/i386/linux
        APPEND tasks=standard pkgsel/language-pack-patterns= pkgsel/install-language-support=false vga=normal initrd=ubuntu-installer/i386/initrd.gz --

LABEL 32expert
        MENU LABEL Ubuntu i386 Expert
        MENU INDENT 1
        KERNEL ubuntu-installer/i386/linux
        APPEND priority=low vga=normal initrd=ubuntu-installer/i386/initrd.gz --

LABEL 32cli-expert
        MENU LABEL Ubuntu i386 Expert CLI
        MENU INDENT 1
        KERNEL ubuntu-installer/i386/linux
        APPEND tasks=standard pkgsel/language-pack-patterns= pkgsel/install-language-support=false priority=low vga=normal initrd=ubuntu-installer/i386/initrd.gz --

LABEL 32rescue
        MENU LABEL Ubuntu i386 Rescue
        MENU INDENT 1
        KERNEL ubuntu-installer/i386/linux
        APPEND vga=normal initrd=ubuntu-installer/i386/initrd.gz rescue/enable=true --

MENU SEPARATOR

LABEL -64
        MENU LABEL Ubuntu x68_64:
        MENU DISABLE

LABEL 64install
        MENU LABEL Ubuntu x86_64 Install
        MENU INDENT 1
        KERNEL ubuntu-installer/amd64/linux
        APPEND vga=normal initrd=ubuntu-installer/amd64/initrd.gz --

LABEL 64cli
        MENU LABEL Ubuntu x86_64 CLI
        MENU INDENT 1
        KERNEL ubuntu-installer/amd64/linux
        APPEND tasks=standard pkgsel/language-pack-patterns= pkgsel/install-language-support=false vga=normal initrd=ubuntu-installer/amd64/initrd.gz --

LABEL 64expert
        MENU LABEL Ubuntu x86_64 Expert
        MENU INDENT 1
        KERNEL ubuntu-installer/amd64/linux
        APPEND priority=low vga=normal initrd=ubuntu-installer/amd64/initrd.gz --

LABEL 64cli-expert
        MENU LABEL Ubuntu x86_64 Expert CLI
        MENU INDENT 1
        KERNEL ubuntu-installer/amd64/linux
        APPEND tasks=standard pkgsel/language-pack-patterns= pkgsel/install-language-support=false priority=low vga=normal initrd=ubuntu-installer/amd64/initrd.gz --

LABEL 64rescue
        MENU LABEL Ubuntu x86_64 Rescue
        MENU INDENT 1
        KERNEL ubuntu-installer/amd64/linux
        APPEND vga=normal initrd=ubuntu-installer/amd64/initrd.gz rescue/enable=true --
{{< /prettify >}}

I can now boot the local HDD (default, in case I don't want any of the network boot options), securely wipe drives, install windows (via unattended), or use any of the features from the ubuntu disks (both 64bit and 32bit).

I would like to add some other options at a later date such as BSD/Solaris Installers or knoppix network boot as the main use for this are for fixing PCs for people (hence windows and knoppix) and a side benefit of making installing OSs in VMs easier (VM network boots to the boot menu for me to install from)

If anyone wants to know more about the setup or has any questions, just use the comment form.
