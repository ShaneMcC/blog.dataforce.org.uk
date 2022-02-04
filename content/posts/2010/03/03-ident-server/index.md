---
title: Ident Server
author: Dataforce
type: post
date: 2010-03-03T22:53:00+00:00
url: /2010/03/ident-server/
category:
  - Code
  - General
  - IRC

---
I recently encountered a problem on a server that I manage where by the oidentd server didn't seem to be working.

Manual tests worked, but connecting to IRC Servers didn't.

I tried switching oidentd with ident2 and the same problem.

After switching back, and a bit of debugging later it appeared that the problem was that the IRC Servers were expecting spaces in the ident reply, whereas oidentd wasn't giving them.

I then quickly threw together an xinet.d-powered ident server with support for spoofing.

<!--more-->

First the xinet.d config:

```shell
service ident
{
	disable = no
	socket_type = stream
	protocol = tcp
	wait = no
	user = root
	server = /root/identServer.php
	nice = 10
}
```

Unfortunately yes, this does need to run as root otherwise it is unable to see what process is listening on a socket. In future I plan to change it to allow it to run without needing to be root (by using sudo for the netstat part)

Now for the code itself:

**Edit:** The code is now available on github: [ShaneMcC/phpident](https://github.com/ShaneMcC/phpident)

I welcome any comments about this, or any improvements and hope that it will be useful for someone else.
