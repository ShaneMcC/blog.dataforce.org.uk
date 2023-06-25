---
title: "Remote LVM-on-LUKS (via ISCSI) with automatic decrypt on boot"
author: Dataforce
url:  /2023/06/remote-crypttab-on-boot/
image: luks-encryption.png
description: Ensuring remote encrypted LVM-on-LUKS filesystems are correctly enabled at boot time
type: post
date: 2023-06-25T15:45:24Z
category:
  - General
  - Proxmox
---

I have recently added some iscsi-backed storage to my [proxmox](https://www.proxmox.com/en/)-based server environment, primarily as an off-server location to store backup data.

For a multitude of reasons, such as the sensitive nature of the data, the fact that the physical storage lies outside of my control, and just good security hygiene - I wanted to ensure that the data is all encrypted at rest.

I wanted to be able to use this iscsi as a storage target for proxmox allowing me to just add the volumes to VMs allowing HA, and I didn't want to have to do encryption inside every VM incase I accidentally forgot to enable it for one of the VMs (remember, the storage is hosted external to me so I have no control over the physical access to it) so to do this I have made use of LUKS encryption on the iscsi block device that I am presented with and then I run LVM over the top of this. ([LVM-on-LUKS](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS) as-opposed to [LUKS-on-LVM](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system#LUKS_on_LVM))

<!--more-->

The initial setup is fairly straight forward, I'm using `iscsi` and `multipathd` to gain access to the block device which ends up being presented to my servers as `/dev/mapper/san0`:

```shell
root@alersi:~# multipath -ll
san0 (somewwidhere) dm-7 TrueNAS,iSCSI Disk
size=3.0T features='1 queue_if_no_path' hwhandler='0' wp=rw
`-+- policy='round-robin 0' prio=1 status=active
  |- 8:0:0:0 sdf 8:80 active ready running
  `- 9:0:0:0 sdg 8:96 active ready running
root@alersi:~#
```

I then used `fdisk` to partition this into a single large partition which presents as `/dev/mapper/san0-part1`. (This step was perhaps not needed but gives me options in future.)

After this, I was able to encrypt the partition and add it to `/etc/crypttab` to allow linux to decrypt it (I am using a keyfile on each server that is able to decrypt the partition rather than needing a password):

```shell
# Encrypt the Partition
cryptsetup luksFormat /dev/mapper/san0-part1
# Add the key
cryptsetup luksAddKey /dev/mapper/san0-part1 /root/san0_keyfile
# Allow mounting
blkid /dev/mapper/san0-part1
echo "san0-part1_crypt      UUID=<BLKID>  /root/san0_keyfile  luks,discard,_netdev" >> /etc/crypttab
# Log out/in and decrypt the volume to check this all works:
iscsiadm  -m node --targetname "iqn.2005-10.org.freenas.ctl:shane" --logout
iscsiadm  -m node --targetname "iqn.2005-10.org.freenas.ctl:shane" --login
systemctl daemon-reload
systemctl start systemd-cryptsetup@san0part1_crypt
```
(For the other hosts, they don't need the `cryptsetup` bits, but need the rest)

And now with the new `/dev/mapper/san0part1_crypt` device, I can enable LVM as normal:
```shell
pvcreate /dev/mapper/san0part1_crypt
vgcreate san /dev/mapper/san0part1_crypt
```

And get that added to proxmox as a shared LVM [storage](https://pve.proxmox.com/wiki/Storage) which all hosts can then see and use.

This is all working great. VMs can move around between the hosts and the data is all encrypted when outside my control.


However, I noticed recently when rebooting the nodes that when the devices came back, they didn't automatically decrypt the volume as expected. (I have it marked as `_netdev` so was expecting it to work). I've previously done LUKS-on-LVM based storage and mounted that as a storage directory on the hypervisors and that worked just fine, so I was perplexed at why this didn't work.

I figured I must have just forgot to enable it on startup, but apparently... this isn't permittied:
```shell
root@alersi:~# systemctl enable systemd-cryptsetup@san0part1_crypt
Failed to enable unit: Unit /run/systemd/generator/systemd-cryptsetup@san0part1_crypt.service is transient or generated.
root@alersi:~#
```

Well then. That's inconvenient.

At the same time I was doing this, [Simon](https://www.simonmott.co.uk/) was also going through the [same experience](https://www.simonmott.co.uk/2023/06/auto-mount-luks-without-a-filesystem/).

Simon noticed the issue before I did so did a lot of initial research into it as per his own blog post, but eventually settled on a bit of a dirty work around for the problem.


I noticed this at around 3am as I as mid-way through upgrading my nodes to the recently released Proxmox 8, I didn't fancy delaying my upgrade too much while investigating futher.

So quickly applied Simon's workaround to my own hosts and continued my upgrade.

Almost immediately, I hated it. It felt wrong, it felt like a dirty solution (Sorry Simon!), and suddenly I had a need to figure out if there was a better way.

> [03:08] **Dataforce**: I hate this. I've also now added this.<br>
> ...<br>
> [03:19] **Dataforce**: I'm convinced there must be a better more correct way<br>
> [03:19] **Dataforce**: but fuck it<br>
> [03:19] **Dataforce**: I cba to fuck around finding out just now<br>
> ...<br>
> [03:34] **Dataforce**: I have found the real fix.<br>

So while one of the nodes was in the process of upgrading, I started looking into it more[^1]:

- [03:08] Searched for `{{< search "systemd cryptsetup automatic" >}}`
- [03:08] Searched for `{{< search "systemd cryptsetup not running automatically" >}}`
- [03:10] Searched for `{{< search "systemd cryptsetup not starting on boot" >}}`
- [03:13] Searched for `{{< search "systemd lvm on luks" >}}`
- [03:13] Searched for `{{< search "systemd lvm on luks crypttab not starting" >}}`
- [03:14] Searched for `{{< search "systemd lvm crypttab startup" >}}`
- [03:15] Searched for `{{< search "systemd-cryptsetup-generator" >}}`
- [03:15] Searched for `{{< search "systemd-cryptsetup-generator enable at boot" >}}`
- [03:16] Searched for `{{< search "systemd-cryptsetup-generator activate at boot" >}}`
- [03:16] Searched for `{{< search "systemd-cryptsetup-generator iscsi" >}}`
- [03:21] Searched for `{{< search "systemd enable crypttab without fstab" >}}`
- [03:21] Searched for `{{< search "systemd activate remote crypttab on boot" >}}`
- [03:22] Searched for `{{< search "systemd list active targets" >}}`
- [03:22] Searched for `{{< search "systemd remote-cryptsetup" >}}`

Eventually the search of of `{{< search "systemd-cryptsetup-generator iscsi" >}}` led me to https://github.com/systemd/systemd/issues/4642 which implied it definitely should be able to do it as support was explicitly added for the `_netdev` parameter in crypttab.

Then `{{< search "systemd activate remote crypttab on boot" >}}` finally led to https://bugzilla.redhat.com/show_bug.cgi?id=1783263 which gave me the answer (that I should have probably been able to figure out myself earlier/quicker).

It seems that by default on some installations, the `remote-cryptsetup.target` is not enabled for systemd, so you need to enable it:

```shell
systemctl enable remote-cryptsetup.target
```

After doing this, and undoing the quick-hack-from-Simon, I let the current node finish it's upgrade and reboot... and it all worked, the node came back and managed to correctly decrypt the disk automatically. Hooray!

[^1]: Yes, I am just showing you my search history as SEO-Fodder.