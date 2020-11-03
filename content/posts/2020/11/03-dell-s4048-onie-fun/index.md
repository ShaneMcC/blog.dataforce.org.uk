---
title: Fun with Dell S4048 and ONIE
author: Dataforce
url:  /2020/11/dell-s4048-onie-fun/
image: s4048.png
description: Fun with Dell S4048 and ONIE Firmware
type: post
date: 2020-11-03T03:01:26Z
category:
  - Networking
---

In `$DayJob` we make use of Dell S4048-ON Switches for 10G Top-of-Rack (ToR) switching and also sometimes 10G Aggregation/Core for smaller deployments. They're fairly flexible devices with a high number of 10G ports, some 40Gs and they can do L3 ports and L2 ports. You can also run them either Stacked or in VLT mode for redundancy purposes.

In addition these things use ONIE (Open Network Install Environment) and can run different firmware images - though we almost exclusively run these with DNOS 9 which is the Force10 FTOS code that Dell acquired some time ago rather than DNOS 10.

One evening, I was tasked with an "emergency" build request. We had some kit being shipped to a remote PoP the following day and the intended routers were delayed, so we needed to get something quickly and temporarily in place to take a BGP Transit Feed and deliver VRRP to the rest of the kit. A spare S4048 we had lying around would do the job sufficiently for the time period needed. I figured it wouldn't take too long to get the base config needed and get it ready to be shipped with the rest of the kit.

So I got the Datacenter to rack/cable/console it so that I could begin configuration then set aside some time in the evening to do the work.

As I was watching the switch boot up I noticed something odd. Turns out the last engineer who had used this device had chosen to install the OpenSwitch OPX ONIE firmware on it instead of the usual DNOS9 firmware. So much for my quick and easy config.

At this point, I could have just reloaded the device into the ONIE installer environment and installed DNOS9 and been done with it all. But, I had a fairly open evening, and I'd not yet really played about much with any of the alternative ONIE OSes, so armed with my Yak Sheers, I thought I'd have a look around.

(After all this, I then re-imaged the device onto our standard deployment image of DNOS9 and completed the required config work that I was supposed to be doing.)



I found the [OpenSwitch OPX Configuration Guide](http://archive.openswitch.net/docs/3.0.0/openswitch_opx_300_config_guide.pdf) and started having a read.

TL;DR: It's a Debian box, use `ip` and `/etc/network/interfaces` to configure it.

So I added an IP address to 1 of the interfaces (`e101-001-0` for the first 10G interface on the device) and some default routing and brought up the link, something like:

```bash
ip addr add 192.0.2.2/30 dev e101-001-0
ip route add 0.0.0.0/0 via 192.0.2.1
ip link set dev e101-001-0 up
```

And lo-and-behold, my switch now had internet access..

```bash
admin@OPX:~$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=119 time=1.31 ms
^C
--- 8.8.8.8 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.313/1.313/1.313/0.000 ms
admin@OPX:~$
```

Now I could ssh to it and have a look around.

Logging in drops you into a fairly standard debian shell and we can learn a bit about the device:

```bash
admin@OPX:~$ lscpu
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                2
On-line CPU(s) list:   0,1
Thread(s) per core:    1
Core(s) per socket:    2
Socket(s):             1
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 77
Model name:            Intel(R) Atom(TM) CPU  C2338  @ 1.74GHz
Stepping:              8
CPU MHz:               1750.071
BogoMIPS:              3500.14
Virtualization:        VT-x
L1d cache:             24K
L1i cache:             32K
L2 cache:              1024K
NUMA node0 CPU(s):     0,1
Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 movbe popcnt tsc_deadline_timer aes rdrand lahf_lm 3dnowprefetch epb kaiser tpr_shadow vnmi flexpriority ept vpid tsc_adjust smep erms dtherm arat
admin@OPX:~$
```
```bash
admin@OPX:~$ free -m
              total        used        free      shared  buff/cache   available
Mem:           3937         516        2460          13         961        3189
Swap:             0           0           0
admin@OPX:~$
```
```bash
admin@OPX:~$ df -h
Filesystem                Size  Used Avail Use% Mounted on
udev                      2.0G     0  2.0G   0% /dev
tmpfs                     394M   14M  381M   4% /run
/dev/mapper/OPX-SYSROOT1  6.8G  1.7G  4.8G  26% /
tmpfs                     2.0G     0  2.0G   0% /dev/shm
tmpfs                     5.0M     0  5.0M   0% /run/lock
tmpfs                     2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/sda4                 6.8M  2.0M  4.2M  33% /mnt/boot
/dev/sda2                 120M   13M   99M  12% /mnt/onie-boot
admin@OPX:~$
```

It's got a fairly weak ATOM CPU, and 4G of RAM, approximately the same as what you'd get in a cheap £10/month VPS. Disk space is basically non-existent at less than 5GB.

Nothing to write home about here, but that's ok - this is just the management plane, it doesn't _need_ to be performant. Infact, I'd be disappointed if it was, as it would be a waste in a device like this.

Lets have a look around some more with opx and see what we can see.

There are a whole bunch of `opx-` prefixed commands to interact with the hardware:
```bash
root@OPX:~# opx-show-
opx-show-alms             opx-show-interface        opx-show-log              opx-show-packages         opx-show-stats            opx-show-transceivers     opx-show-vrf
opx-show-env              opx-show-interface-stats  opx-show-mac              opx-show-route            opx-show-system-status    opx-show-version
opx-show-global-switch    opx-show-lag              opx-show-mirror           opx-show-sflow            opx-show-transceiver      opx-show-vlan
root@OPX:~# opx-config-
opx-config-beacon         opx-config-global-switch  opx-config-interface      opx-config-log            opx-config-mirror         opx-config-sflow          opx-config-vlan           opx-config-vxlan.py
opx-config-fanout         opx-config-hybrid-group   opx-config-lag            opx-config-mac            opx-config-route          opx-config-switch         opx-config-vrf
root@OPX:~#
```

The output of these seems reasonably friendly and usable:

```bash
root@OPX:~# opx-show-version
OS_NAME="OPX"
OS_VERSION="3.1.0"
PLATFORM="S4048-ON"
ARCHITECTURE="x86_64"
INTERNAL_BUILD_ID="OpenSwitch blueprint for Dell 1.0.0"
BUILD_VERSION="3.1.0.0-rc1"
BUILD_DATE="2018-12-19T12:31:44-0800"
INSTALL_DATE="2019-11-21T16:38:13+00:00"
SYSTEM_UPTIME= 28 minutes
SYSTEM_STATE= running


UPGRADED_PACKAGES=no
ALTERED_PACKAGES=no
root@OPX:~#
```
```bash
root@OPX:~# opx-show-transceiver
Port 1
    Present:            yes
    Type:               SFP+ 10GBASE-SR
    Vendor:             FS
    Vendor part number: SFP-10GSR-85
    Vendor revision:    0000
    Serial number:      G1234567890
    Qualified:          yes
    Temperature:        31.0 deg. C
    Temperature state:  nominal
    Voltage:            3.29099988937 V
    Voltage state:      nominal
    High power mode:    no
Port 2
    Present:            yes
    ...
Port 52
    Present:            yes
    Type:               QSFP+ 40GBASE-CR4-1.0M
    Vendor:             FS
    Vendor part number: QSFP-PC005
    Vendor revision:    4100
    Serial number:      C1234567890-1
    Qualified:          yes
    Temperature:        0.0 deg. C
    Temperature state:  nominal
    Voltage:            0.0 V
    Voltage state:      nominal
    High power mode:    yes
    ...
root@OPX:~#
```
```bash
root@OPX:~# opx-show-transceiver --port 1
Port 1
    Present:            yes
    Type:               SFP+ 10GBASE-SR
    Vendor:             FS
    Vendor part number: SFP-10GSR-85
    Vendor revision:    0000
    Serial number:      G1234567890
    Qualified:          yes
    Temperature:        31.0 deg. C
    Temperature state:  nominal
    Voltage:            3.29099988937 V
    Voltage state:      nominal
    High power mode:    no
root@OPX:~#
```
```bash
root@OPX:~# opx-ethtool e101-001-0
Settings for e101-001-0:
    Channel ID:   0
    Transceiver Status: Enable
    Media Type: SFP+ 10GBASE-SR
    Part Number: SFP-10GSR-85
    Serial Number: G1234567890
    Qualified: Yes
    Administrative State: UP
    Operational State: UP
    Supported Speed (in Mbps):  [1000, 10000]
    Auto Negotiation : off
    Configured Speed   : 10000
    Operating Speed   : False
    Duplex   : full
root@OPX:~#
```
```bash
root@OPX:~# opx-ethtool -e e101-001-0
Show media info for e101-001-0
...
base-pas/media/port-type = 1
base-pas/media/wavelength-pico-meters = 850000
...
base-pas/media/slot = 1
base-pas/media/port = 1
...
base-pas/media/category-string = SFP+
base-pas/media/capability = 4
base-pas/media/diag-mon-type = 104
base-pas/media/channel-count = 1
base-pas/media/type = 5
...
base-pas/media/tx-power-low-warning-threshold = -7.99970722198
base-pas/media/insertion-timestamp = 140016931634256
...
base-pas/media/display-string = SFP+ 10GBASE-SR
base-pas/media/vendor-pn = SFP-10GSR-85
base-pas/media/current-temperature = 31.0
...
root@OPX:~#
```
```bash
root@OPX:~# opx-show-env
Chassis
...
        Vendor name:            DELL
        Service tag:            xxxxxxx
        PPID:                           xxxxxxxxxxxxxxxxxxxx
        Platform name:
        Product name:                   S4048ON
        Hardware version:               A02
        Number of MAC addresses:        256
        Base MAC address:               00:11:22:33:44:55
Power supplies
        Slot 1
                Present:                Yes
                Operating status:       Up
                Fault type:             OK
                Vendor name:
                Service tag:            AEIOU##
                PPID:                   xxxxxxxxxxxxxxxxxxxx
                Platform name:
                Product name:
                Hardware version:               A00
                Input:                  AC
                Fan airflow:            Reverse
        Slot 2
                ...
Fan trays
        Slot 1
                Present:                Yes
                Operating status:       Up
                Fault type:             OK
                Vendor name:
                Service tag:            AEIOU##
                PPID:                   xxxxxxxxxxxxxxxxxxxx
                Platform name:
                Product name:
                Hardware version:               A00
                Fan airflow:            Reverse
        Slot 2
                ...
        Slot 3
                ...
Fans
        Fan 1, PSU slot 1
                Operating status:       Up
                Fault type:             OK
                Speed (RPM):            10320
                Speed (%):              57
        Fan 1, PSU slot 2
                ...
        Fan 1, Fan tray slot 1
                Operating status:       Up
                Fault type:             OK
                Speed (RPM):            10121
                Speed (%):              53
        Fan 2, Fan tray slot 1
                ...
        Fan 1, Fan tray slot 2
                ...
        Fan 2, Fan tray slot 2
                ...
        Fan 1, Fan tray slot 3
                ...
        Fan 2, Fan tray slot 3
                ...
Temperature sensors
        Sensor CPU board sensor, Card slot 1
                Operating status:               Up
                Fault type:                     OK
                Temperature (degrees C):        31
        Sensor NPU board sensor, Card slot 1
                Operating status:               Up
                Fault type:                     OK
                Temperature (degrees C):        35
        Sensor system-NIC board sensor 1, Card slot 1
                Operating status:               Up
                Fault type:                     OK
                Temperature (degrees C):        33
        Sensor system-NIC board sensor 2, Card slot 1
                Operating status:               Up
                Fault type:                     OK
                Temperature (degrees C):        31
        Sensor NPU temp sensor, Card slot 1
                Operating status:               Up
                Fault type:                     OK
                Temperature (degrees C):        48
root@OPX:~#
```

Ok, so we've got basic connectivity, but what about if we wanted to do more, like BGP?

The configuration guide says:

> Use the `apt-get install` command to install the latest Debian 9 (stretch) release of the FRR package.

apt you say...

The guide suggested installing the .deb by hand, but I figured it would probably work properly via apt:

```bash
apt-get update
apt-get install apt-transport-https
curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
export FRRVER="frr-stable"
echo deb https://deb.frrouting.org/frr stretch $FRRVER | sudo tee -a /etc/apt/sources.list.d/frr.list
apt-get update
apt-get install frr
```

And it actually installed.

At this point, a normal network-person would have then probably continued to look at `frr` and getting it working (I'm sure it works reasonably well, I didn't look).

I'm not a normal network-person. I also like to play about with servers as well.

So armed with the knowledge that `apt` worked... I decided to try installing `docker`... because of course that's the next thing you try to install on a network switch.

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" | sudo tee -a /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io
```

And it worked. Docker was installed. And seemingly working.

```bash
root@OPX:~# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
root@OPX:~#
```

So the next obvious thing, what can I run to test this?

How about... this blog?

```bash
root@OPX:~# docker run shanemcc/blog.dataforce.org.uk
Unable to find image 'shanemcc/blog.dataforce.org.uk:latest' locally
latest: Pulling from shanemcc/blog.dataforce.org.uk
cbdbe7a5bc2a: Pull complete
c554c602ff32: Pull complete
eda7f6504221: Pull complete
08afec60697d: Pull complete
Digest: sha256:fd3c2e1d0a8ab6e9af30f4293135cffa2dba644aded797fe79188307f2ae0a2d
Status: Downloaded newer image for shanemcc/blog.dataforce.org.uk:latest

```

Well, it seemed to be running:

```bash
root@OPX:~# docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS              PORTS               NAMES
02399b6f09b9        shanemcc/blog.dataforce.org.uk   "nginx -g 'daemon of…"   55 seconds ago      Up 53 seconds       80/tcp              pensive_kapitsa
root@OPX:~#
```

But didn't seem to actually work. Maybe it was too good to be true?

Oh wait - the networking on this is probably a bit weird, maybe the docker bridge/NAT stuff doesn't work... What if we try host-based networking?

```bash
root@OPX:~# docker run --rm --network host --name shaneblogtest shanemcc/blog.dataforce.org.uk
192.0.2.253 - - [24/Sep/2020:20:09:49 +0000] "GET / HTTP/1.1" 200 32706 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.59 Safari/537.36" "-"
192.0.2.253 - - [24/Sep/2020:20:09:49 +0000] "GET /css/allStyles-b2de97faf57b5af84d20b6bbcd1f47ab.css HTTP/1.1" 200 25159 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.59 Safari/537.36" "-"
192.0.2.253 - - [24/Sep/2020:20:09:49 +0000] "GET /wp-content/uploads/2016/05/header.png HTTP/1.1" 200 7938 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.59 Safari/537.36" "-"
192.0.2.253 - - [24/Sep/2020:20:09:49 +0000] "GET /wp-content/uploads/2016/05/ShaneNewColour.png HTTP/1.1" 200 5866 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.59 Safari/537.36" "-"
...
```

That worked, and then I was able to see this blog in all it's wonder, served from a switch!

{{< postimage src="s4048blog-blur.png" side="none" alt="Blog running on a switch" >}}

(Some of you will note that I didn't actually expose a port properly in the first command, so it may well have worked if I'd done it correctly, I didn't try any further)

I was greatly amused at the idea of this, mainly because it's so stupid (running the blog on a £3k Switch that's no more powerful than a £10/month VPS).

But also thinking about it more, this is quite exciting.

ONIE/OPX can run on x86 hardware or in a VM with KVM/QEMU/VAGRANT etc so you can actually have local test environments that function similarly to your live production switches, and with docker you can run applications on these devices to handle configuration/automation etc and get all the advantages of a modern development pipeline with reproduceable builds and an easy installation process (`docker run ...`).

Or you could run a blog. ¯\\\_(ツ)\_/¯
