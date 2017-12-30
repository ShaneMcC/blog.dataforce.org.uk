---
title: Ubuntu on HP Compaq Mini 311c-1030SA
author: Dataforce
type: post
date: 2010-08-10T01:41:53+00:00
url: /2010/08/ubuntu-on-hp-compaq-mini-311c-1030sa/
featured_image: /wp-content/uploads/2010/08/311c-1030SA.jpg
category:
  - General

---
I recently purchased a HP Compaq Mini 311c-1030SA with nvidia ION and built in 3G, unfortunately the 3G card is a "UN2400" which isn't supported right out of the box as it requires proprietary firmware.

This post is mostly notes for myself on getting the UN2400 3G card inside it working enough to use.

This post assumes that the netbook is running ubuntu maverick <del datetime="2010-12-13T13:18:39+00:00">(which is currently in alpha but seems to work just fine)</del> as it has gobi_loader as a package and a kernel which supports it.

When I installed ubuntu on here, I kept the original windows partition in case it was needed. I'm glad I did otherwise this would have been more awkward as some files from the windows installation are needed to get this working.

Before doing anything, boot the windows partition and connect to 3G from the HP Connection manager (This generates some log files which we need). Also change the settings on the 3G card not to turn off on shutdown. (Not sure if the last bit is needed but I did it anyway from reading other posts online about this card.)

Now back in ubuntu, lets make this work:

{{< prettify shell >}}
# Install gobi-loader
sudo apt-get install gobi-loader

# Create missing directory
sudo mkdir -p /lib/firmware/gobi

# Use full paths for gobi_loader
sudo sed -i 's@"gobi_loader@"/lib/udev/gobi_loader@' /lib/udev/rules.d/60-gobi.rules

# Mount windows partition
sudo mkdir /mnt/windows
sudo mount /dev/sda1 /mnt/windows

# The HP Connect software comes with some pppd and chat scripts already for us.
sudo cp "/mnt/windows/Documents and Settings/All Users/HP/HPCM/WWAN/ppprc" /etc/ppp/peers/hpcm
sudo cp "/mnt/windows/Documents and Settings/All Users/HP/HPCM/WWAN/chat" /etc/ppp/hpcm-chat

# Update file path and add us to the dip group
sudo sed -i 's@~/chat@/etc/ppp/hpcm-chat@' /etc/ppp/peers/hpcm
sudo usermod -a -G dip `id -nu`

# Find which images were push to the card so we can copy them
sudo iconv --from-code UTF-16 --to-code UTF-8 "/mnt/windows/Documents and Settings/All Users/Application Data/QUALCOMM/QDLService2k/QDLService2kHP.txt" | grep -i "sending image"
{{< /prettify >}}

This produces something like:

{{< prettify shell >}}
08/04/2010 23:09:55.093 [01840] QDL sending image file: C:\Program Files\Qualcomm\Images\HP\UMTS\AMSS.mbn
08/04/2010 23:10:00.281 [01840] Sending image file: C:\Program Files\Qualcomm\Images\HP\UMTS\Apps.mbn
08/04/2010 23:10:02.046 [01840] Sending image file: C:\Program Files\Qualcomm\Images\HP\4\UQCN.mbn
{{< /prettify >}}

Copy the images referenced in the log file:

{{< prettify shell >}}
sudo cp /mnt/windows/Program\ Files/QUALCOMM/Images/HP/UMTS/amss.mbn /lib/firmware/gobi/
sudo cp /mnt/windows/Program\ Files/QUALCOMM/Images/HP/UMTS/apps.mbn /lib/firmware/gobi/
sudo cp /mnt/windows/Program\ Files/QUALCOMM/Images/HP/4/UQCN.mbn /lib/firmware/gobi/
{{< /prettify >}}

Next you'll want to stop modemmanager corrupting the firmware whilst it is being uploaded by blacklisting the non-modem version of the device:

{{< prettify shell >}}
echo 'ATTRS{idVendor}=="03f0", ATTRS{idProduct}=="241d", ENV{ID_MM_DEVICE_IGNORE}="1"' >> /lib/udev/rules.d/77-mm-usb-device-blacklist-custom.rules
{{< /prettify >}}

Now restart the machine so that udev picks up the device and uploads the firmware to it.

Once restarted you should be able to connect to the mobile broadband like so:

{{< prettify shell >}}
pon hpcm
{{< /prettify >}}

In maverick network-manager understands that this card is a mobile broadband card, so it should be possible to configure it rather than using the ppp/chat scripts from hpcm but using the scripts is a good way to test if it works, and they have in them the information required by network-manager.

<del datetime="2010-12-13T13:18:39+00:00">I just stick with pon/poff however as NetworkManager on KDE doesn't seem to even bother to try and connect (I've had success with nm-applet tho so I might just use that).</del> In KDE, I've found that KNetworkManager isn't the best at using this device (or my work VPN), so I use nm-applet to configure and use this device unless I don't have a working X session (a common occurrence when using beta versions of ubuntu!).

* * *

Now, for the ION chip.

Firstly install the nvidia driver from jockey (also install the broadcom STA driver for wireless) and restart.

Now:

{{< prettify shell >}}
apt-get install vlc libva1 vdpau-va-driver nvidia-185-libvdpau pkg-config
nvidia-xconfig
shutdown -r now
{{< /prettify >}}

<del datetime="2010-10-24T03:48:49+00:00">Now this should be all thats needed, but it doesn't appear to work right now, VLC video playback of h264 is still unwatchable, I shall keep trying.</del>

**Update:** Using the final-release version of Maverick I have got this working in VLC. Open VLC, go to Tools > Preferences and go to "Input & Codecs" and enable "GPU Acceleration".

<del datetime="2010-12-13T13:18:39+00:00">**Update 2:** Unfortunately, the final release version of Maverick has [This Bug](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/621743) which stops the 3G card working all the time.</del>


**Update 3:** After updating this netbook to natty, the 3G bug still exists. Unfortunately I have yet to get round to git-bisecting against the kernel, as I don't fancy compiling multiple kernels on a netbook!


**Update 4:** As a result of the [bug report](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/621743) I submitted about this bug, I was directed to [another bug report](https://bugs.launchpad.net/ubuntu/+source/modemmanager/+bug/686418) which described the same problem on a slightly different Qualcomm based device. (Modem requires firmware to be loaded and swaps device IDs before/after, modem works 1 in 20 times, etc). The alternative bug report suggests that modemmanager is actually at fault rather than the kernel.

As such, the following solution does fix the problem:

{{< prettify shell >}}
echo 'ATTRS{idVendor}=="03f0", ATTRS{idProduct}=="241d", ENV{ID_MM_DEVICE_IGNORE}="1"' >> /lib/udev/rules.d/77-mm-usb-device-blacklist-custom.rules
{{< /prettify >}}


followed by restarting. (In theory, killing modemmanager, loading the firmware and restarting modemmanager will also work)

modemmanager now no longer corrupts the firmware as it is being uploaded and the device is fully usable. I'm still wondering what changed between the kernel 2.6.35-14 and 2.6.35-17 versions in maverick that caused this to stop working, but I'm glad to finally have a solution to this.

I have updated the post to include this step in the process of getting this working.

* * *

I did originally get the 3g card working on lucid which was a bit more awkward (it involved recompiling some drivers to allow gobi_loader) but I switched to maverick as it was easier (and also I wanted VLC support for the ION chip which has recently been added in maverick)

I used [these instructions](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/554099/comments/14) to make it work on lucid in the past.
