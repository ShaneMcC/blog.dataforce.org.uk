---
title: Cisco XConnect L2Protocol Handling
author: Dataforce
url:  /2020/04/cisco-l2protocol-handling/
image: graphSample.png
description: A look at differences in how l2protocols on xconnects are handled in different cisco platforms
type: post
date: 2020-04-27T03:06:10Z
category:
  - Networking
---

In `$DayJob` we make fairly extensive use of MPLS ATOM Pseudowires (XConnects) between our various datacenter locations to enable services in different sites to talk to each other at layer2.

The way I describe this to customers is that in essence these act as a "long cable" from Point-A to Point-B. The customer gets a cable at each side to connect to their kit, but in the middle of it there is magic that routes the packets over our network rather than an actual long-cable. Packets that enter 1 side will be pushed out the other side, and vice-versa. We don't need to know or care what these packets are, we are just transparently transporting them.

<!--more-->

As a quick primer, imagine the following network:

{{< postimage src="sample1.png" side="none" alt="Sample Base Network" >}}

This fictional network has 2 main sites, York and Manchester, and 2 smaller sites at Leeds and Birmingham, they have 4 individual L2 circuits between the sites forming a ring, and have routers that are MPLS capable and configured appropriately.

A new customer in each site wants layer-2 connectivity between their devices. In the past if we had connected switches at each location we may have provided spanned-VLANs (with QinQ) through the sites, but instead now we can provide this using MPLS XConnects which will be transparent to the customer. We provision 2 of these for redundancy on different devices at each side, and we end up with something like this:

{{< postimage src="sample2.png" side="none" alt="Sample Network With XConnects" >}}

The customer has 2 services, Green and Blue, and they are able to connect their switches to them and everything works as if the 2 devices were directly connected. The customer is unaware of the Leeds/Birmingham devices as the provider network is transparent and everything including things such as CDP/LLDP/STP/LACP are all happily transported from site to site. The customer doesn't see our network, and can treat these 2 cables as they see fit (such as running LACP over the top). The customer is happy.

Back at `$DayJob` we use a mixture of devices to do this depending on the age of the site and how long the services have been in place for.

In our case a number of these are provisioned between pairs of Cisco 7600 devices, although as we have been phasing these out we have been moving towards using ASR920s instead for newer connections. As we deploy these and phase out the 7600s, we normally provide customers with new XConnects on the new ASR920s, and then move them across to them and remove the old one, this results in most of these XConnects being between devices of the same family. We have some cross-family (920 to 7600) XConnects, but these are few and far between and we had never really noticed any issues with them.

However, one day a few days after some emergency maintenance work to decommission a failing 7600 device and move the XConnect services on it onto an ASR920, I started to notice some of our transcontinental links had developed an unusual and unexpected traffic pattern. A link that was normally fairly quiet in Asia started looking like this:

{{< postimage src="xmas-tree.png" side="none" alt="Christmas Tree Network" >}}

Traffic would slowly creep up and up and up, then reset a bit then keep going, different links were seeing different levels of traffic, but eventually over time these links would all start to fill up eventually getting closer and closer to maxing out the links if left alone.

Looking at the various links that had developed this pattern, I was able to narrow down which customer network was having the issue and noticed that it had started around the time we had replaced the 7600. I realised it must be related to the maintenance work and discovered specifically that there was ports with XConnect configs on them from the new ASR920 to remote 7600s. If I shut down one of the ports, the traffic completely vanished. And then started again once it was unshut. (As seen on the above graph.).

Looking more at this - at first glance the XConnects appeared to behave fine (they were all showing up, and traffic *was* clearly passing across them) there was a subtle underlying problem: On these cross-family XConnects, certain important L2Protocols (such as CDP, LACP and Spanning-Tree BPDUs) were behaving unidirectionally.

What we were seeing was that these L2Protocol packets when sent from devices at the 7600 side were successfully reaching devices the ASR920 side, but were not successfully transiting the other direction.

So much for my transparent "really long cable".

Without these important packets working in all directions, we had ended up with a network loop on this customer platform and a broadcast storm that was going all the way round our global network from London to Tokyo to San Francisco to Virginia and back to London.

Thankfully because the loop was going the long-way-round, the speed of light was able to prevent the storm growing too quickly resulting in the fun traffic graphs. Unfortunately, shutting down a port every 12 hours is not a solution, and in this case I didn't have the option of converting all of these XConnects into same-family XConnects due to the availability of ASR920 ports in the various sites - so we needed to get to the bottom of exactly what was happening.

I got some kit together and started to lab it up. A couple of switches, an old 7600 and an ASR920. MPLS between the 7600 and ASR920 and then build a simple XConnect between the 2 switches:

{{< postimage src="labSetup.png" side="none" alt="Lab Setup" >}}

This was able to reproduce the issue quite nicely. One side could see the other over CDP, the other side could not.

So now that I could reproduce it, I started to look into more details about the differences in the 2 devices. We're doing simple whole-port based XConnects here so the config is fairly straight forward.

On the 7600, we have something like:
```bash
interface GigabitEthernet1/1
  mtu 9216
  no ip address
  no keepalive
  xconnect 10.255.0.2 100 encapsulation mpls
!
```
Nice and simple. We set the MTU on the port to 9216 (to allow us to receive and transport full 1500 and 9000 byte frames), and tell it to set up an XConnect to the other device with the circuit ID of 100 and encapsulate this via the MPLS network.

On the ASR920, we have something like:
```bash
interface GigabitEthernet0/0/1
  mtu 9216
  service instance 1 ethernet
    encapsulation default
    l2protocol tunnel
    xconnect 10.255.0.1 100 encapsulation mpls
  !
!
```
As you can see, there is a little bit more to this config, but this is mostly due to how this product is designed to be used.

We're defining here a `service instance` and then we're using `encapsulation default` to tell the router that it should use this for any traffic that is not matched by any other `service instance` on this port (We can have other `service instance` blocks that match different types of traffic, eg `encapsulation untagged` for all non-VLAN traffic, or `encapsulation dot1q 1234` to match traffic tagged with vlan `1234` etc). We're also specifying handling of `l2protocol` traffic here and telling the device that we want to tunnel it to the other side, this is similar to older switches when doing `l2protocol-tunnel` when doing QinQ.

So these 2 config blocks in isolation seem fine, and when paired with an identical configuration at the other side - everything works as expected. Alas when paired with each other, they do not.

So, blinkers on based on the fact this config worked between devices of the same type, I started looking into this and attempting to make it work.

I tried changing the firmware on the ASR920s in case there was some issue with different versions. We'd not noticed problems before, and definitely had some cross-family XConnects from the early deployments before we had ASR920s in more of our sites, so maybe something had broken at some point. Seemed reasonable.

I tried both older and newer versions of the firmware. Nope. The problem persisted.

Newer versions are slightly more verbose about their `l2protocol` command, and will display the config something like: `l2protocol tunnel cdp stp vtp pagp dot1x lldp lacp udld` - but this doesn't seem to actually change anything.

So I then tried a variety of different ways of building the XConnects. The 7600 side was pretty set-in-stone, but the ASR920 has a few other ways we could try:
```bash
interface GigabitEthernet0/0/1
  mtu 9216
!
l2vpn xconnect context 100
  member GigabitEthernet0/0/1
  member 10.255.0.1 100 encapsulation mpls
!
```
or:
```bash
interface GigabitEthernet0/0/1
  mtu 9216
!
l2vpn xconnect context 100
  member GigabitEthernet0/0/1
  member Pseudowire100
!
interface Pseudowire 100
  encapsulation mpls
  neighbor 10.255.0.1 100
!
```
Nope. These options didn't behave either - I also didn't really like them as it splits the config up too much in the `show running-config` output - you can't easily see that `Gi0/0/1` is being used as an XConnect just from looking at it.

So I went back to the original config.

Given that L2Protocol traffic entering ASR920 was what wasn't working, and this was the only side that we were specifically calling out the `l2protocol` handling, I started looking more at that.

Removing that line didn't help, it made things worse between 2 ASR920s as no `l2protocol` traffic passed at all, so it was definitely required. So I looked at other options for this command. As it happens `tunnel` is not the only option here on the ASR920s, we also have `drop`, `forward` and `peer`.

Neither `drop` or `peer` seemed useful, so I changed my config from `tunnel` to `forward` and suddenly everything started behaving.

So now my ASR920 config looked like:
```bash
interface GigabitEthernet0/0/1
  mtu 9216
  service instance 1 ethernet
    encapsulation default
    l2protocol forward
    xconnect 10.255.0.1 100 encapsulation mpls
  !
!
```

And my 2 switches were finally able to speak CDP to each other, and sent STP BPDUs.

Turns out what was happening was that the 7600 side just forwards the l2protocols on to the remote side without doing anything with them, however on the ASR920 side you have to specify what to do with them. We had used `l2protocol tunnel` on these as this was similar to the `l2protocol-tunnel` command we had used on older devices doing QinQ that were the first ones we replaced with ASR920s (in pairs) - this worked fine and thus became part of our standard config.

So with this config, the 7600 would receive l2protocol packets and forward them onto the ASR920. When the ASR920 received the forwarded l2protocol packets from the 7600s they happily passed them out the port and everything worked as expected. However when the ASR290 received them inbound, they modified them and encapsulated them for tunneling before forwarding them onto their partner (this would be necessary if we weren't doing MPLS and the link between our 2 devices was a switched L2 network to stop them being processed there). If this partner was another ASR920 configured the same way it would be expecting this and would unmodify/de-encapsulate them before forwarding them on and everything worked fine. However the 7600 was not expecting them in this format, and just forwarded them on as-is and the customer devices then didn't understand what they were seeing and ignored them. Changing to `l2protocol forward` causes the ASR920s to behave in the same way as the 7600s and everything is happy.

Having figured this out, I went back to the recently-replaced ASR920 and dutifully changed the config on any of the xconnects that were facing 7600s to be `l2protocol forward` - and low-and-behold my christmas-tree graphs immediately ceased across the board.

So why hadn't we seen this before despite having cross-family XConnects elsewhere? Looking at the limited instances we had of this, I think we just got lucky. Either the customer only had a single XConnect, or wasn't using them for switches, or it happened to be unidirectional in the right way and STP blocked the port correctly.

Goes to show that even though something looks like it might be working fine doesn't always mean it is, there may still be subtle parts of it that are not

Thankfully I was able to get to the bottom of this one.
