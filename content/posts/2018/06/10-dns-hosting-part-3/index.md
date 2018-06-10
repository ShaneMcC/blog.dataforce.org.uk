---
title: "DNS Hosting - Part 3: Putting it all together"
author: Dataforce
url:  /2018/06/dns-hosting-part-3/
image: dns.png
description: Running MyDNSHost
type: post
date: 2018-06-10T18:31:21Z
category:
  - General
  - DNS
  - Code
---

In my [previous](/2018/01/dns-hosting-part-1/) [posts](/2018/01/dns-hosting-part-2/) I discussed the history leading up to, and the eventual rewrite of my DNS hosting solution. So this post will (finally) talk briefly about how it all runs in production on [MyDNSHost](https://mydnshost.co.uk/).

Shortly before the whole rewrite I'd found myself playing around a bit with `Docker` for another project, so I decided early on that I was going to make use of Docker for the main bulk of the setup to allow me to not need to worry about incompatibilities between different parts of the stack that needed different versions of things, and to update different bits at different times.

The system is split up into a number of containers (and could probably be split up into more).

To start with, I had the following containers:

 - API Container - Deals with all the backend interactions)
 - WEB Container - Runs the main frontend that people see. Interacts with the API Container to actually do anything.
 - DB Container - Holds all the data used by the API
 - BIND Container - Runs an instance of bind to handle DNSSEC signing and distributing DNS Zones to the public-facing servers.
 - CRON Container - This container runs a bunch of maintenance scripts to keep things tidy and initiate DNSSEC signing etc.

The tasks in the CRON container could probably be split up more, but for now I'm ok with having them in 1 container.

This worked well, however I found some annoyances when redeploying the API or WEB containers causing me to be logged out from the frontend, so another container was soon added:

 - MEMCACHED Container - Stores session data from the API and FRONTEND containers to allow for horizontal scaling and restarting of containers.

In the first instance, the API Container was also responsible for interactions with the BIND container. It would generate zone files on-demand when users made changes, and then poke BIND to load them. However this was eventually split out further, and another 3 containers were added:

 - GEARMAN Container - Runs an instance of [Gearman](http://gearman.org/) for the API container to push jobs to.
 - REDIS Container - Holds the job data for GEARMAN.
 - WORKER Container - Runs a bunch of worker scripts to do the tasks the API Container previously did for generating/updating zone files and pushing to BIND.

Splitting these tasks out into the WORKER container made the frontend feel faster as it no longer needed to wait for things to happen and could just fire the jobs off into GEARMAN and let it worry about them. I also get some extra logging from this as the scripts can be a lot more verbose. In addition, if a worker can't handle a job it can be rescheduled to try again and the workers can (in theory) be scaled out horizontally a bit more if needed.

There was some initial challenges with this - the main one being around how the database interaction worked, as the workers would fail after periods of inactivity and then get auto restarted and work immediately. This turned out to be mainly due to how I'd pulled out the code from the API into the workers. Whereas the scripts in API run using the traditional method where the script gets called and does it's thing (including setup) then dies, the WORKER scripts were long-term processes, so the DB connections were eventually timing out and the code was not designed to handle this.

Finally, more recently I added statistical information about domains and servers, which required another 2 containers:

 - INFLUXDB Container - Runs [InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/) to store time-series data and provide a nice way to query it for graphing.
 - CHRONOGRAF Container - Runs [Chronograf](https://www.influxdata.com/time-series-platform/chronograf/) to allow me to easily pull out data from INFLUXDB for testing.

That's quite a few containers to manage. To actually manage running them, I make use of `Docker-Compose` primarily (to set up the various networks, volumes, containers) etc. This works well for the most part, but there are a few limitations around how it deals with restarting containers that cause fairly substantial downtime with upgrading WEB or API. To get around this I wrote a small bit of orchestration scripting that uses docker-compose to scale the WEB and API containers up to 2 (Letting docker-compose do the actual creation of the new container), then manually kills off the older container and then scales them back down to 1. This seems to behave well.

So with all these containers hanging around, I needed a way to deal with exposing them to the web, and automating the process of ensuring they had SSL Certificates (using [Let's Encrypt](https://letsencrypt.org/)). Fortunately [Chris Smith](https://www.chameth.com) has already solved this problem for the most part in a way that worked for what I needed. In a [blog post](https://www.chameth.com/2016/05/21/docker-automatic-nginx-proxy/) he describes a set of docker containers he created that automatically runs nginx to proxy towards other internal containers and obtain appropriate SSL certificates using DNS challenges. For the most part all that was required was running this and adding some labels to my existing containers and that was that...

Except this didn't quite work initially, as I couldn't do the required DNS challenges unless I hosted my DNS somewhere else, so I ended up adding support for HTTP Challenges and then I was able to use this without needing to host DNS elsewhere. (And in return Chris has added support for using MyDNSHost for the DNS Challenges, so it's a win-win). My orchestration script also handles setting up and running the automatic nginx proxy containers.

This brings me to the public-facing DNS Servers. These are currently the only bit not running in Docker (though they could). These run on some standard Ubuntu 16.04 VMs with a small setup script that installs bind and an extra service to handle automatically adding/removing zones based on a special "[catalog zone](https://kb.isc.org/article/AA-01401/0/A-short-introduction-to-Catalog-Zones.html)" due to the versions of bind currently in use not yet supporting them natively. The transferring of zones between the frontend and the public servers is done using standard DNS Notify and AXFR. DNSSEC is handled by the backend server pre-signing the zones before sending them to the public servers, which never see the signing keys.

By splitting jobs up this way, in theory it should be possible in future (if needed) to move away from [BIND](https://www.isc.org/downloads/bind/) to alternatives (such as [PowerDNS](https://www.powerdns.com) or so).

As well as the [public service](https://mydnshost.co.uk/) that I'm running, all of the code involved (All the containers and all the Orchestration) is available [on Github](https://github.com/mydnshost) under the MIT License. Documentation is a little light (read: pretty non-existent) but it's all there for anyone else to use/improve/etc.
