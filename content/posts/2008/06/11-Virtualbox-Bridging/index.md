---
title: Virtualbox Bridging
author: Dataforce
type: post
date: 2008-06-11T10:56:17+00:00
url: /2008/06/Virtualbox-Bridging/
category:
  - Code
  - General

---
_**Edit:** This is now pretty much unneeded, the new version of VirtualBox seems to handle this all nicely on its own._

As I mentioned in my last post, One of the useful advantages of the network boot setup is that I can use it to quickly install virtual machines.

Now a few things:

* My Desktop is a lot more powerful than my server, so I run the virtual machines on it.
* I use virtualbox rather than vmware.
* All the network boot stuff is on my server not my desktop (obviously) </ul>

So in order to allow this, virtualbox needed to be setup to bridge to my existing adapter, this was quite straight forward, pretty much exactly as the manual said.

<!--more-->

```shell
sudo apt-get install bridge-utils
```

Edit `/etc/network/interfaces`, and add

```shell
auto br0
iface br0 inet dhcp
    bridge_ports eth0
```

Now the next suggestion was to setup a `tap0` device and tell virtualbox to use that, or to use a dynamic configuration.

The dynamic configuration sounded better as it meant I didn't need to remember to add a new tap device for each vm.

The suggested dynamic configuration suggests using kdesu/gksudo and a script in the home dir of the user that will setup and cleaup the tap device (this means inputting your password every tiem you start/stop the VM and requiring a separate script for each user that wants to have a vm with bridging) this seemed rather annoying so I came up with an alternative.

**/usr/bin/setuptap**
```bash
#!/bin/bash

# Make sure we are root
if [ $(whoami) != root ]; then
        exit 1;
fi;

# Create an new TAP interface for the user and remember its name.
interface=`VBoxTunctl -b -u ${SUDO_USER}`
# If for some reason the interface could not be created, return 1 to
# tell this to VirtualBox.
if [ -z "$interface" ]; then
        exit 1
fi
# Write the name of the interface to the standard output.
echo ${interface}

# Bring up the interface.
/sbin/ifconfig ${interface} up
# And add it to the bridge.
/usr/sbin/brctl addif br0 ${interface}
```

**/usr/bin/cleanuptap**
```bash
#!/bin/bash

# Make sure we are root
if [ $(whoami) != root ]; then
        exit 1;
fi;

# Remove the interface from the bridge.  The second script parameter is
# the interface name.
/usr/sbin/brctl delif br0 $2
# And use VBoxTunctl to remove the interface.
VBoxTunctl -d $2
```

Now these scripts run with sudo as any user will setup the tap device for that user (thats what ${SUDO_USER} is for)

This still requires a password for starting/stopping the VMs tho, so we use

`sudo visudo`

or if you prefer nano

`sudo EDITOR=nano visudo`

and add

```shell
# Allow virtualbox users to setup/cleanup tap devices
%vboxusers        ALL=NOPASSWD:/usr/bin/setuptap,/usr/bin/cleanuptap
```

now:

* configure virtualbox to attach the network device to a "host interface"
* leave the Interface name blank (setuptap creates the next available one)
* Setup Application: `sudo /usr/bin/setuptap`
* Terminate Application: `sudo /usr/bin/cleanuptap`

And virtualbox will be able to create/destroy the tap device as needed.

However. there is still one problem, DHCP will not work for these VMs without a little help, so we need to:

```shell
sudo apt-get install dhcp3-relay
```

and answer the questions asked. (DHCP Server IP, and Interface to listen on (`br0`))

Virtualbox unfortunatly seems to need a little push to actually network boot, so I also use an etherboot iso to actually boot from the network along with the "PCnet-FAST III" adapter type.

and thats all there is to it, you can now network boot and dhcp from virtual machines not hosted on the server.
