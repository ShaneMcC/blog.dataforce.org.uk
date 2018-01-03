---
title: DNS Hosting - Part 1
author: Dataforce
url:  /2018/01/dns-hosting-part-1/
image: dns.png
description: Hosting my own DNS.
type: post
date: 2018-01-03T01:15:06Z
category:
  - General
  - DNS
---

For as long as I can remember I've hosted my own DNS. Originally this was via cpanel on a single server that I owned and then after a while I moved to a new server away from cpanel and moved to doing everything myself (web, email, dns) - hand-editing zone files and serving them via BIND.

This was great for learning, and this worked well for a while but eventually I ended up with more servers, and a lot more domains. Manually editing DNS Zone files and reloading BIND was somewhat of a chore any time I was developing things or spinning up new services or moving things between servers - I wanted something web-based.

There wasn't many free/cheap providers that did what I wanted (This was long before [Cloudflare](https://cloudflare.com/) or [Route 53](https://aws.amazon.com/route53/)), so around 2007 I did what any (_in_)sane person would do - I wrote a custom control panel for managing domains. and email. and it was multi-user. and it had billing support. and a half-baked ticket-system... ok, so I went a bit overboard with the plans for it. But mainly it controlled DNS and throughout it's lifetime that was the only bit that was "completed" and fully functional.

The DNS editing was simple, it parsed BIND Zone files, presented them in a table of text input fields and let me make changes. (This is an ever-so-slight upgrade to "hand-edit zone files")

For security reasons the webserver couldn't write to the bind zone file directory, so it made use of temporary files that the webserver could write to and then a cron script made these temporary files live by moving them into the bind zone file directory and reloading the zone with `rndc reload example.org`. Reading of zone data in the editor would look for the zone in the temporary directory first before falling back to the bind directory so that any pending edits didn't get lost before the cronjob ran.

After I had the editor working I wanted redundancy. I made use of my other servers and added secondary name servers that synced the zones from the master. There was a cronjob on the master server to build a list of valid zones, and separate cronjobs on the secondary servers that synced this list of zones every few hours. Zone data came in via AXFR from the master to the secondaries.

I even added an API of sorts for changing zone data. It wasn't good ( `GET` requests to crafted URLs such as `GET /api/userapi-key/dns/key=domain-api-key/type=A/setrecord=somerecord.domain.com/ttl=3600/data=1.1.1.1` or so) but it let me automate DNS changes which I used for automated website failover.

{{% postimage src="sorencp.png" side="left" alt="DNS Control Panel" %}}

This all kinda worked. There was a bunch of delays waiting for cronjobs to do things (Creating new zones needed a cronjob to run and this needed to run before zones could be edited (and before they existed on the secondary servers). Editing zones then needed to wait for a cronjob to make the changes live, etc) but ultimately it did what I needed, and the delays weren't really a problem. The cronjobs on the master server ran every minute, and the secondary servers ran every 6 hours. Things worked, DNS got served, I could edit the records, job done?

A few years later (2010) I realised that the DNS editing part of the control panel was the only bit worth keeping, so I made plans to rip it out and make it a standalone separate service. The plan was to get rid of BIND and zone-file parsing, and move to PowerDNS which had a mySQL backend that I could just edit directly. The secondary servers would then run with the main server configured as a _supermaster_ to remove the need for cronjobs to sync the list of zones.

So I bought a generic domain [`mydnshost.co.uk`](https://mydnshost.co.uk) (You can never have too many domain names!) and changed all the nameservers at my domain registrar to point to this generic name... and then did absolutely nothing else with it (except for minor tweaks to the control panel to add new record types) for a further 7 years. Over the years I'd toy again with doing something, but this ultimately never panned out.

Whilst working on another project that was using [letsencrypt](https://letsencrypt.org) for SSL certificates, I found myself needing to use dns-based challenges for the domain verification rather than http-based verification. At first I did this using my old DNS system. I was using [dehydrated](https://dehydrated.de) for getting the certificates so I was able to use a custom shell script that handled updating the DNS records (and sleeping for the appropriate length of time to ensure that the cronjob had run before letting the letsencrypt server check for the challenge) - but this felt dirty. I had to add in support for removing records to my API (in 10 years I'd never needed it as I always just changed where records pointed) and it just felt wrong. The old API wasn't really very useful for anything other than very specific use cases and the code was nasty.

So, in March 2017 I finally decided to make use of the [`mydnshost.co.uk`](https://mydnshost.co.uk) domain and actually build a proper DNS system which I (appropriately) called [MyDNSHost](https://mydnshost.co.uk) - and I'll go into more detail about that specifically in part 2 of this series of posts.
