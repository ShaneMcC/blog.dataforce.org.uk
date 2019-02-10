---
title: Limiting the effectiveness of DNS Amplification
author: Dataforce
type: post
date: 2013-08-03T02:25:19+00:00
url: /2013/08/limiting-the-effectiveness-of-dns-amplification/
category:
  - General
  - Networking

---
I recently had the misfortune of having a server I am responsible for used as a target for DNS Amplification, and thought I'd share how I countered this. (Whilst this was effective for me, your mileage may vary, but if this actually helps someone then it's worth posting about.)

This particular server was the main recursor for the site that it was located at (And this was correctly limited not to allow open recursion), but was also authoritative for a small selection of domains. (Yes I know mixing recursors and resolvers is bad.)

The problem only came about when I needed to relocate the server to another site. In order to ensure continuity of service whilst the nameserver IP change propagated, I added some port-forwards at the old site that redirected DNS traffic to the new site. This however meant that all DNS traffic going towards the server came from an IP that was trusted for recursion. Oops.

After adding the port-forwards, but before updating the nameservers, I got distracted and ended up forgetting about this little hack, until the other day when I suddenly noticed that both sites were suffering due to large numbers of packets. (It's worth noting, that in this case both sites were actually on standard ADSL connections, so not a whole lot of upload bandwidth available here!)

After using `tcpdump` it became apparent quite quickly what was going on, and it reminded me that I hadn't actually made the nameserver change yet. This left me in a situation where the server was being abused, but I wasn't in a position to just remove the port forward without causing a loss of service.

I was however able to add a selection of `iptables` rules to the firewall at the first site (that was doing the forwarding) in order to limit the effectiveness of the attack, which should be self explanatory (along with the comments):

{{< highlight shell >}}
# Create a chain to store block rules in
iptables -N BADDNS

# Match all "IN ANY" DNS Queries, and run them past the BADDNS chain.
iptables -A INPUT -p udp --dport 53 -m string --hex-string "|00 00 ff 00 01|" --to 255 --algo bm -m comment --comment "IN ANY?" -j BADDNS
iptables -A FORWARD -p udp --dport 53 -m string --hex-string "|00 00 ff 00 01|" --to 255 --algo bm -m comment --comment "IN ANY?" -j BADDNS

# Block domains that are being used for DNS Amplification...
iptables -A BADDNS -m string --hex-string "|04 72 69 70 65 03 6e 65 74 00|" --algo bm -j DROP --to 255 -m comment --comment "ripe.net"
iptables -A BADDNS -m string --hex-string "|03 69 73 63 03 6f 72 67 00|" --algo bm -j DROP --to 255 -m comment --comment "isc.org"
iptables -A BADDNS -m string --hex-string "|04 73 65 6d 61 02 63 7a 00|" --algo bm -j DROP --to 255 -m comment --comment "sema.cz"
iptables -A BADDNS -m string --hex-string "|09 68 69 7a 62 75 6c 6c 61 68 02 6d 65 00|" --algo bm -j DROP --to 255 -m comment --comment "hizbullah.me"

# Rate limit the rest.
iptables -A BADDNS -m recent --set --name DNSQF --rsource
iptables -A BADDNS -m recent --update --seconds 10 --hitcount 5 --name DNSQF --rsource -j DROP
{{< /highlight >}}

This flat-out blocks the DNS queries that were being used for domains that I am not authoritative for, but I didn't want to entirely block all "IN ANY" queries, so rate limits the rest of them. This was pretty effective at stopping the ongoing abuse.

It only works of course if the same set of IPs are repeatedly being targeted (remember, these are generally spoofed IPs that are actually the real target). Once the same target is spoofed enough times, it gets blocked and no more DNS packets will be sent to it, thus limiting the effectiveness of the attack (how much it limits it, depends on how much packets would otherwise have been aimed at the unsuspecting target).

Here is my iptables output as of right now, considering the counters were cleared Friday morning:

```shell
root@rakku:~ # iptables -vnx --list BADDNS
Chain BADDNS (2 references)
    pkts      bytes target     prot opt in     out     source               destination
  458939 29831035 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           STRING match "|0472697065036e657400|" ALGO name bm TO 255 /* ripe.net */
 2215367 141783488 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           STRING match "|0473656d6102637a00|" ALGO name bm TO 255 /* sema.cz */
       0        0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           STRING match "|0968697a62756c6c6168026d6500|" ALGO name bm TO 255 /* hizbullah.me */
       1     2248 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           STRING match "|03697363036f726700|" ALGO name bm TO 255 /* isc.org */
    5571   385042            all  --  *      *       0.0.0.0/0            0.0.0.0/0           recent: SET name: DNSQF side: source
    5542   374343 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           recent: UPDATE seconds: 10 hit_count: 5 name: DNSQF side: source
root@rakku:~ #
```

Interestingly, the usual amplification target, isc.org, wasn't really used this time.

As soon as the nameserver IP updated (seems the attackers were using DNS to find what server to attack), the packets started arriving directly at the new site and thus no longer matched the recursion-allowed subnets and the attack stopped being effective (and then eventually stopped altogether once I removed the port-forward which stopped the first site responding recursively also)

In my case I applied this where I was doing the forwarding, as the attack was only actually a problem if the query ended up at that site and to limit the outbound packets being forwarded, however this would work just fine if implemented directly on the server ultimately being attacked.
