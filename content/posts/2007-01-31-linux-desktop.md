---
title: Linux Desktop
author: Dataforce
type: post
date: 2007-01-31T00:48:55+00:00
url: /2007/01/linux-desktop/
categories:
  - Code
  - General
  - IRC

---
With the release of windows vista, comes the start-of-the-end for Windows XP. with its EOL (End-Of-Life) date now set at January 30th 2008 (thats less than a year away), people (by people I mean windows users) who are unable to upgrade to vista (due to Lack of computing power or so) or don't want it (its crap, proprietary, riddled with DRM and probably bugs - Microsoft are already producing SP1!) need to start looking for alternatives, unless they want to stay using an unsupported (this means no more bug/security fixes) Operating System.

Imo, The best alternative is some derivative of Linux. (Although there is others such as MacOS x86 although its not supported on non-mac hardware, FreeBSD but I don't think its desktop oriented, and others such as beOS or so)

As of Saturday 27/1/07 I have started using KUbuntu Linux as the main OS on my desktop, as a trial to see how well I can get by without my "trusty" windows installation.

I chose KUbuntu due to its use of KDE, and the fact it was ubuntu, which is one of the more well-established desktop-friendly distros of Linux available at this time. It also has one of the best communities and followings, as well as a solid base (Debian).

(A distro (distribution) is the term used to refer to a specific version/flavor of Linux. Other distros include Fedora Core, Redhat, Slackware, Debian and Gentoo)

The installation went smoothly, it resized my NTFS partition to allow for an ext3 partition, and installed away happily, I was even able to irc/browse the web whilst it did it due to the live cd based installer (Which is just pure genius!)

After the install, I rebooted (twice into windows first to allow the NTFS Journal to be reset for the new size, and then to confirm it was "clean", then into Linux) and was greeted with a nice graphical login screen, that had detected the correct resolution for my monitor and everything.

The next task was to update the system, and install the nvidia drivers so that i could use dual monitors. This was a relatively painless process with kubuntu. I edited the "sources.list" file (alt+f2 then `kdesu kate /etc/apt/sources.list`) and uncommented the disabled repositories and opened a konsole window (alt+f2 then type `konsole`) and entered the following commands `sudo apt-get update` `sudo apt-get upgrade` `sudo apt-get install nvidia-glx`. Alas after rebooting, X didn't want to work and I was greeted with a text-only console. Fortunatly the fix was easy, adding `deb http://albertomilone.com/drivers/edgy/latest/32bit/ binary/` to the sources.list and running the above commands again and rebooting fixed the problem.

The next task was to enable ntfs write. Following http://ubuntuforums.org/showthread.php?t=217009 I was able to simply add some repositories to my sources.list, `sudo apt-get install ntfs-config` and then run ntfs-config and follow the prompts. Restarted and it was done.

I now had a fully usable desktop, running both monitors at their native resolution, and i was even able to easily setup the task bar to show only tasks on the monitor it is on.

Since installing I've installed quite a few packages (apt-get makes it really easy) and done alot of customisation. Suffice to say i'm pretty happy with my install, and don't think I'll be returning to windows any time soon.

One package I would recommending installing would be `beryl` (Google for "Beryl Ubuntu" for installation guide, and check youtube for videos of what it can do as well as the standard window decorating).

The great thing about Ubuntu is the community behind it at http://ubuntuforums.org/. pretty much any problem you have, has been reported there by someone else, and subsequently solved - this makes problem solving a snap! (If a problem isn't there, searching Google for "Ubuntu &lt;problem&gt;" usually solves most things.) Another benefit is the fact it derives from debian which is a well established distribution in the Linux community, and subsequently has a lot of packages available for non-source applications should you not want to be compiling from source all the time to add things.

A tip to KUbuntu users wishing to follow some of the guides on the forums that were designed for the standard gnome-based version of Ubuntu, open a konsole and run the following 2 commands: `sudo ln -s /usr/bin/kate /usr/bin/gedit` and `sudo apt-get install gksudo synaptic`. These 2 commands install `gksudo` which some of the guides use to gain root, synaptic which is the most referenced package manager, and makes the editor `kate` work when the guides say gedit (as gedit just looks ugly on KDE. An alternative would be to run `sudo apt-get install gksudo synaptic gedit` which will give you the real gedit in all its ugliness.)

Overall, I'm now a happy linux-desktop user, and I've yet to reboot back to windows!

You can get a copy of KUbuntu here: http://www.kubuntu.org/download.php :)

Edit: http://www.ubuntuguide.org provides a page full of instructions on how to install commonly-wanted stuff.
