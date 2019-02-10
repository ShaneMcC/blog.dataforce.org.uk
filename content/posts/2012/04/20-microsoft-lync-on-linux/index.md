---
title: Microsoft Lync on Linux
author: Dataforce
type: post
date: 2012-04-20T11:55:26+00:00
url: /2012/04/microsoft-lync-on-linux/
image: TuxLync.png
description: How to get chatting on Lync when using Linux.
category:
  - General

---
**Update:** This post still gets a lot of search traffic hits, but is now over a year old, and I no longer have a need to use Lync, so haven't needed to keep this working.

I believe that the Ubuntu repos now contain new enough versions of SIPE that the deb mentioned here shouldn't be needed any more, but that the rest of the instructions should still be valid.

* * *

**Update 2:** I need to use LYNC again. Pidgin from the default Ubuntu repos does indeed now appear to work just fine with a custom user agent. In addition, I've also had some success with "[WYNC](http://fisil.com/linuxlync.html)" which works pretty well but has a few minor issues of it's own.

* * *

Recently at work we have started using Lync internally. Whilst this is great for the Windows and Mac users among us, not so much for those of us running on Linux.

However, it turns out that it is possible to get basic Lync support working quite easily. I can see people, talk to people, people can talk to me – I can send files to people, but people can't send file to me. I've not tried any video/voice stuff but I suspect it doesn't work.

It’s done using "[sipe](http://sipe.sourceforge.net/)" – basically an open source implementation of the Extended SIP/SIMPLE protocol Lync uses for chat.

The basic steps on Ubuntu are:

  * <del datetime="2013-05-18T13:22:42+00:00">Install the latest pidgin from pidgin devs ppa</del> apt-get install pidgin pidgin-sipe
  * <del datetime="2013-05-18T13:22:42+00:00">Download sipe</del>
  * <del datetime="2013-05-18T13:22:42+00:00">Compile it</del>
  * Connect to lync.

<del datetime="2013-05-18T13:22:42+00:00">The compiling step is required because we use Office365 for Lync which needs the latest version of SIPE for which a deb does not yet appear to exist. However, I have uploaded my compiled deb which can be found below.</del>

Instructions for Ubuntu (using a pre-compiled deb I've uploaded):

```shell
sudo apt-add-repository ppa:pidgin-developers/ppa
sudo apt-get update
sudo apt-get install pidgin
wget http://www.myfileservice.net/pidgin-sipe_1.13.1-2_i386.deb
sudo dpkg -i pidgin-sipe_1.13.1-2_i386.deb
```

Once this is done you can then open pidgin, and add an "Office Communicator" account, using the following settings:

**First tab (Basic)**<br>
Login: _email address_<br>
Username: _email address_<br>
Password: _password_

**Second tab (Advanced)**<br>
Server/port: _blank_<br>
Connection Type: _Auto_<br>
User Agent: _UCCAPI/4.0.7577.314 OC/4.0.7577.314_<br>
Auth Scheme: _TLS-DSK_

Un-tick /Use single sign on/, leave everything below it blank

Ignore the other 2 tabs

Done. Connect, see buddies :)

Amusingly, at home, I’ve actually had more success on Linux than windows! On my windows machine, opening LyncSetup.exe seems to just do nothing at all, the process appears to be running, but no setup window appears.

Issues encountered:

 * <del datetime="2013-05-18T13:22:42+00:00">The version of pidgin-sipe currently in Ubuntu repos is too old to work with Office 365 (needs 1.13.0, hence compiling myself)</del>
 * <del datetime="2013-05-18T13:22:42+00:00">Version of pidgin in ubuntu was old, I installed a new version to be sure</del>
 * A colleague of mine seems to have had no success with these steps - pidgin seems to crash immediately after trying to connect

<del datetime="2013-05-18T13:29:11+00:00">The pidgin-sipe deb above also builds the required "telepathy" binaries – so I’m going to have a go at getting it working with KDE’s native messaging client rather than pidgin, but for now for IM at least, pidgin is quite usable.</del> (As I no longer need to use Lync, I never did get round to trying this)
