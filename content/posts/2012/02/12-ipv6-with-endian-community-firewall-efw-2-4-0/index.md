---
title: IPv6 with Endian Community Firewall (EFW) 2.4.0
author: Dataforce
type: post
date: 2012-02-12T09:15:56+00:00
url: /2012/02/ipv6-with-endian-community-firewall-efw-2-4-0/
category:
  - Code
  - Endian
  - General
  - IPv6

---
First post in over a year! Oops.

For a while now, my home ADSL provider (EntaNET) has provided me with an IPv6 allocation, but I've never really used it (Its been on my to-do list for some time) primarily due to the fact that it is unsupported by Endian which I use for my home router/firewall.

However the other day after being asked about IPv6 at my day job, I decided I wanted to get this working, and decided to document it here in case it can assist anyone else in future. (I also finally got round to completing the [Hurricane Electric IPv6 Certification](http://ipv6.he.net/certification) up to sage level)

There's a few things worth noting before we continue here.

  1. I use a [Draytek Vigor 120](http://www.draytek.co.uk/products/vigor120.html) for my adsl modem - this is a PPPoA to PPPoE bridge. This means that my Endian box uses PPPoE to get its Internet connection, and directly receives an IPv4 address via the PPP session. There is no "PPP Half-Bridge" tricks here (such as where Modem does authentication, then DHCPs the address to Endian).
  2. Due to Endian lacking support for IPv6 you will need to use SSH to configure this, and any Endian upgrades will probably reverse a fair chunk of it. (Also, some reconfigurations may also undo things) - so with this in mind the rest of this guide assumes you are familiar with SSH and have successfully logged in as root to the Endian box (SSH can be enabled under the "System" section and "SSH Access").
  3. Due to previous requirements, my Endian server is not "pure" in that I have additional packages installed that made this easier. Notably, a complete build environment. This won't be needed here.
  4. This was all done without writing it down, so this documentation is based on my recollection and attempts at replicating various parts on a VirtualBox VM (which can't do PPPoE...). If I've missed anything, please let me know in the comments.
  5. This was done with EFW 2.4.0 and may not work in the latest 2.5.1 version.
  6. I have only had this running for a few days, so there may be some unforeseen issues with this.


With this in mind, we continue to the actual important stuff!

The way EntaNET do IPv6, with a default setup you will get an IP Address allocated over PPP that is in a /64, but you also get a /56 which is routed to you. We will use a /64 from the /56 as the address for the LAN.

For the purposes of this, we are going to assume the following:

  * **2001:DB8:4D51:AA00::/56** - /56 range allocated to us by the ISP
  * **2001:DB8:4D51:AAFF::/64** - /64 range we are going to use internally.
  * **2001:DB8:4D51:FFFF::/64** - /64 range advertised across the PPP session.

The first thing to do, is to have Endian actually ask for IPv6 from the upstream provider at PPP time. This is easy:

```shell
echo "+ipv6" >> /etc/ppp/peers/defaults/pppd-pppoe
```

Assuming that the ADSL provider and modem both support IPv6, and you have been assigned an allocation you will see an IPv6 address attached to ppp0 once your session is active. This is from the PPP /64 and is not part of your /56 allocation.

So now we know that IPv6 works we can disconnect the PPP session.

Now, we actually want to be able to do something with our allocation, so we will want to announce it to our network.

For this, we will need radvd which will send the required RA Packets out to the network. As Endian 2.4.0 is built on Fedora Core 3, we can use the existing package for this, these can currently be found [here](http://archives.fedoraproject.org/pub/archive/fedora/linux/core/3/i386/os/Fedora/RPMS/)

Unfortunately, Endian doesn't quite provide a complete environment, so we will need to force the install to ignore dependencies (specifically, chkconfig and /sbin/service are missing).

```shell
rpm --nodeps -Uvh http://archives.fedoraproject.org/pub/archive/fedora/linux/core/3/i386/os/Fedora/RPMS/radvd-0.7.2-9.i386.rpm
```

We can now configure this to announce our prefix by editing /etc/radvd.conf to something like this:

```shell
interface br0
{
        AdvSendAdvert on;
        MinRtrAdvInterval 3;
        MaxRtrAdvInterval 10;
        AdvHomeAgentFlag off;
        prefix 2001:DB8:4D51:AAFF::/64
        {
                AdvOnLink on;
                AdvAutonomous on;
                AdvRouterAddr off;
        };
};
```

To trick radvd into starting, we also need to create a dummy file that exists in real RedHat-esque distros that Endian doesn't provide:

```shell
echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network
```

We also need to enable IPv6 forwarding:

```shell
sysctl net.ipv6.conf.all.forwarding=1
```

and we should now be able to start radvd:

```shell
/etc/init.d/radvd start
```

Now, if we bring the ppp connection back up, you'll notice that the ppp0 interface no longer gets allocated a routable IPv6 address from the PPP /64. This is because with ipv6 forwarding turned on, this host is now acting as an ipv6 router, and ipv6 routers ignore RA packets.

This isn't a problem.

At this point, your LAN boxes will have IPv6 addresses, but the LAN boxes won't be able to communicate with the internet yet.

To fix this, we need to tell the Endian box how to route traffic, specifically to both our LAN, and the default route:

```shell
route --inet6 add 2001:DB8:4D51:AAFF::/64 dev br0
route --inet6 add default dev ppp0
```

With this however, the Endian box won't have IPv6 connectivity, if this is something that is required, we can do something like this instead:

```shell
ip -6 addr add 2001:DB8:4D51:AAFF::/64 dev br0
route --inet6 add default dev ppp0
```

But remember, that any time Endian makes any changes to the network configuration, this will be lost.

Endian's version of iputils is missing ping6 and traceroute6, but we can install these as follows:

```shell
cd /
curl http://archives.fedoraproject.org/pub/archive/fedora/linux/core/3/i386/os/Fedora/RPMS/iputils-20020927-16.i386.rpm > iputils.rpm
rpm2cpio iputils.rpm | cpio -ivd '*6'
rm iputils.rpm
```

This will give you ping6 etc to allow you to verify everything so far.

The next thing to do then is firewalling, this is done with ip6tables, which again Endian doesn't have, however we can install ip6tables using the iptables-ipv6 package available in the RPM repo above)

```shell
rpm -Uvh http://archives.fedoraproject.org/pub/archive/fedora/linux/core/3/i386/os/Fedora/RPMS/iptables-ipv6-1.2.11-3.1.i386.rpm
```

Now you'll be able to create firewall rules for your IPv6 connectivity. Its worth noting though that this version of ip6tables doesn't support some modules (comment and state that I've seen so far). If you want these modules, then you'll need to compile a newer version of iptables. (I've got a follow up post with a guide for this.)

To support this, I wrote a set of scripts for parsing "formatted-english" rules files into iptables rules, so lets install that and configure some rules.

```shell
cd /root
wget https://github.com/ShaneMcC/Firewall-Rules/zipball/master -O fwrules.zip
unzip fwrules.zip
mv ShaneMcC-Firewall-Rules-* fwrules
cp fwrules/example.rules fwrules/rules.rules
chmod a+x fwrules/run.sh
```

Looking at fwrules/rules.rules should give you a good guide on how the rules work, and you can edit these to your needs.

Once you are happy, the rules can be installed by running:

```shell
./fwrules/run.sh
```

The last thing then is to make this all work automatically.

In theory we should be able to just drop some files into the subfolders of /etc/uplinksdaemon, or into ifup.d or ifdown.d folders inside mkdir /var/efw/uplinks/main/ but neither of these approaches works. So instead we will make a minor modification to /usr/lib/uplinks/generic/hookery.sh and then have a script of our own do it.

Firstly, the minor change and an empty file:

```shell
sed -ri 's#^(.*log_done "Notify uplinks.*)$#\1\n    /sbin/uplinkchanged.sh "$@" >/dev/null 2>&1#' /usr/lib/uplinks/generic/hookery.sh
touch /sbin/uplinkchanged.sh
chmod a+x /sbin/uplinkchanged.sh
```

Now we can put the following into /sbin/uplinkchanged.sh:

```shell
#!/bin/bash

OURPREFIX="2001:DB8:4D51:AAFF::/64"

UPLINK=${1}
STATUS=${2}

if [ "${STATUS}" = "" ]; then
	exit 0;
fi;

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

if [ "${UPLINK}" = "main" ]; then
	if [ "${STATUS}" = "OK" ]; then
		sysctl net.ipv6.conf.all.forwarding=1
		/etc/init.d/radvd start
		route --inet6 add ${OURPREFIX} dev br0 2>&1
		route --inet6 add default dev ppp0
		/root/fwrules/run.sh
	elif [ "${STATUS}" = "FAILED" ]; then
		route --inet6 del default dev ppp0

		ip6tables -F
		ip6tables -X
		ip6tables -P INPUT ACCEPT
		ip6tables -P OUTPUT ACCEPT
		ip6tables -P FORWARD ACCEPT
	fi;
fi;
```

Now when the state of the main uplink changes, the relevant ipv6-related commands will be run to ensure that connectivity remains.

And that's it, you should now have native IPv6 connectivity combined with Endian. Feel free to leave any comments you have regarding this.
