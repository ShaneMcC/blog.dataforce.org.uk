---
title: "Upgrading Ceph in Docker Swarm"
author: Dataforce
url:  /2019/07/upgrading-ceph-in-docker-swarm/
image: ceph.png
description: Upgrading ceph in Docker Swarm Cluster
type: post
date: 2019-07-29T02:02:22Z
category:
  - Code
  - Docker
  - Ceph
---

> This post is part of a series.
>
> 1. [Docker Swarm with Ceph for cross-server files](/2019/02/docker-swarm-with-ceph/)
> 2. Upgrading Ceph in Docker Swarm **(This Post)**
> 3. [Docker Swarm Cluster Improvements](/2021/08/docker-swarm-cluster-improvements/)

This post is a followup to an [earlier blog bost](/2019/02/docker-swarm-with-ceph/) regarding setting up a docker-swarm cluster with ceph.

I've been running this cluster for a while now quite happily however since setting it up, a new version of ceph has been released - nautilus - so now it's time for some upgrades.

> **Note:** This post is out of date now.
>
> I would suggest looking at [this post](/2021/08/docker-swarm-cluster-improvements/) and using the docker-compose based upgrade workflow instead, up to the housekeeping part.

I've mostly followed https://docs.ceph.com/docs/master/releases/nautilus/#upgrading-from-mimic-or-luminous but adapted it for the fact we're running everything in docker. I recommend that you have a read though this yourself first to have an idea of what we are doing and why.

(It's worth noting at this point that this guide was mostly written after the fact based on command history so I may have missed something. It's always a good idea to do this on a test cluster first, or in a maintenance window!)

<!--more-->

Before we begin the upgrade, we should run the following on each node in advance to save time later: `docker pull ceph/daemon:latest-nautilus`

Now we can prepare to update. Firstly on any node we tell ceph not to worry about rebalancing:
```shell
ceph osd set noout
```

Now we can begin actually upgrading ceph. The process is actually quite simple for each daemon type, on each node we stop and remove the old container, then start a new one with the same flags we did in the past, so here we go:

On each node 1 at a time restart the ceph-mon containers:
```shell
docker stop ceph-mon; docker rm ceph-mon
docker run -d --net=host --restart always -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ \
-e MON_IP=$(ip addr show dev eth0 | grep "inet " | head -n 1 | awk '{print $2}' | awk -F/ '{print $1}') \
-e CEPH_PUBLIC_NETWORK=$(ip route show dev eth0 | grep link | grep -v 169.254.0.0 | awk '{print $1}') \
--name="ceph-mon" ceph/daemon:latest-nautilus mon
```
(This is basically the same command that was used before, except we're now specifying that we want to use `ceph/daemon:latest-nautilus` as the image source)


After we have done this, we can check that the upgrade was successful:

`ceph mon versions` should show something like:
```json
{
    "ceph version 14.2.2 (4f8fa0a0024755aae7d95567c63f11d6862d55be) nautilus (stable)": 3
}
```

Now the same for the mgr containers:
```shell
docker stop ceph-mgr; docker rm ceph-mgr
docker run -d --net=host --privileged=true --pid=host -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ --name="ceph-mgr" --restart=always ceph/daemon:latest-nautilus mgr
```
Checking with `ceph mgr versions`

And the osd containers:
```shell
docker stop ceph-osd; docker rm ceph-osd
docker run -d --net=host --privileged=true --pid=host -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ -v /dev/:/dev/ -e OSD_DEVICE=/dev/sdb -e OSD_TYPE=disk --name="ceph-osd" --restart=always ceph/daemon:latest-nautilus osd
```
Checking with `ceph osd versions` (You might want to wait for the output of this command to show that the current node is running the new version before moving on to the next node)


Now we can move onto the MDS containers.

Firstly we need to change `max_mds` to `1` if it's not already (You can check using `ceph fs get cephfs`):
```shell
ceph fs set cephfs max_mds 1
```

Now we should stop all the non-active MDSs. We can see the currently active MDS using: `ceph status | grep -i mds`

And we stop the non-active standby MDSs using:

```shell
docker stop ceph-mds; docker rm ceph-mds
```

And then once ceph status shows only the active MDS, we can restart the remaining one:

```shell
docker stop ceph-mds; docker rm ceph-mds
docker run -d --net=host --name ceph-mds --restart always -v /var/lib/ceph/:/var/lib/ceph/ -v /etc/ceph:/etc/ceph -e CEPHFS_CREATE=1 -e CEPHFS_DATA_POOL_PG=128 -e CEPHFS_METADATA_POOL_PG=128 ceph/daemon:latest-nautilus mds
```

And then restart all the standby MDSs:
```shell
docker run -d --net=host --name ceph-mds --restart always -v /var/lib/ceph/:/var/lib/ceph/ -v /etc/ceph:/etc/ceph -e CEPHFS_CREATE=1 -e CEPHFS_DATA_POOL_PG=128 -e CEPHFS_METADATA_POOL_PG=128 ceph/daemon:latest-nautilus mds
```

At this point, the `max_mds` value can be reset if it was previously anything other than `1`.

And now we can check `ceph mds versions` shows our updated MDSs:
```json
{
    "ceph version 14.2.2 (4f8fa0a0024755aae7d95567c63f11d6862d55be) nautilus (stable)": 3
}
```


Now for some post-upgrade house keeping, on any node:
```shell
ceph osd require-osd-release nautilus
ceph osd unset noout
ceph mon enable-msgr2
```

We should also now update our config files and local version of ceph.

Firstly lets import our current config files into the cluster configuration db, run this on all nodes:
```shell
ceph config assimilate-conf -i /etc/ceph/ceph.conf
```

Then we can upgrade the local ceph tools:
```shell
rpm -e ceph-release; rpm -Uvh https://download.ceph.com/rpm-nautilus/el7/noarch/ceph-release-1-1.el7.noarch.rpm
yum clean all; yum update ceph
```

And update our local config to the minimal config:
```shell
cp -f /etc/ceph/ceph.conf /etc/ceph/ceph.conf.old
ceph config generate-minimal-conf > /etc/ceph/ceph.conf.new
mv -f /etc/ceph/ceph.conf.new /etc/ceph/ceph.conf
```

We should also update our fstab entry to include multiple servers not just the current one, so that we can actually mount properly on startup (this should have been done in the original guide. I learned afterwards!):
```shell
export CEPHMON=`ceph mon dump 2>&1 | grep "] mon." | awk '{print $3}' | sed -r 's/mon.(.*)/\1:6789/g'`
sed -ri "s/.*(:\/\s+\/var\/data\/.*)/$(echo ${CEPHMON} | sed 's/ /,/g')\1/" /etc/fstab
```

This may also now be a good time for other OS updates and a reboot if required (Run `ceph osd set noout` first to stop ceph rebalancing when the node goes down and check `ceph status` to see if the current node is the active MDS and fail it if it is with `ceph mds fail $(hostname -s)` and then `ceph osd unset noout` when we're done.)

Before rebooting we will want to drain the node of active containers:
```shell
docker node update --availability drain `hostname -f`
```

and then undrain it when we're done:
```shell
docker node update --availability active `hostname -f`
```


And that's it! Overall a pretty painless upgrade process, which is nice.
