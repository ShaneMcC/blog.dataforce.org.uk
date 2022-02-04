---
title: Yakuake on OS X – Almost
author: Dataforce
type: post
date: 2008-07-17T07:18:03+00:00
url: /2008/07/Yakuake-on-OS-X-Almost/
category:
  - General

---
For a while now (pretty much since I've been using Linux) I've been using [yakuake](http://en.wikipedia.org/wiki/Yakuake), and I've been looking for something similar for OS X (at the moment I tend to ssh from my desktop to my OS X machine to do anything console like).

I found [visor](http://docs.blacktree.com/visor/visor) which wraps terminal.app, but overall this is a poor replacement primarily for the lack of tab support (I use tabs a lot in yakuake, at the moment on my desktop I have ~15 open)

I tried to get yakuake working on OS X a while ago and failed (it wouldn't compile) so gave up, recently however I decided to try again and have made better progress.

This is what I did, its probably not the best way of doing it (for example, the initial 3GB download could probably be reduced).

<!--more-->

First off, download the "everything" package from http://mac.kde.org/?id=download (its a torrent)

Open a terminal, and cd to the directory you downloaded kde-mac to and run:

`chmod a+x *.pkg/Contents/Resources/postflight`

Then install the kde.mpkg package contained (this installs everything nicely)

Now, back in the terminal:

```shell
sudo /opt/kde4-deps/bin/update-kde-mac.sh
/opt/kde4/bin/kbuildsycoca4
cd ~
svn co svn://anonsvn.kde.org/home/kde/trunk/extragear/utils/yakuake/
PATH=/opt/qt4/bin/:${PATH} cmake -DCMAKE_INSTALL_PREFIX=/opt/kde4/
make
sudo make install
sudo /opt/kde4-deps/bin/update-kde-mac.sh
/opt/kde4/bin/kbuildsycoca4
```

This installs yakuake to `/opt/kde4/bin/yakuake.app` next to the other kde apps.

If you run it however, the first time it runs it will give you the "choose a key" popup, but after that its not yet possible to do anything, pressing the key shows it attempting to appear but not quite getting there :(

Almost :(

Back to visor I guess :(
