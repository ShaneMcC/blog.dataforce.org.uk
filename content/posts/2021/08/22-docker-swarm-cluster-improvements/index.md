---
title: "Docker Swarm Cluster Improvements"
author: Dataforce
url:  /2021/08/docker-swarm-cluster-improvements/
image: swarm.png
description: Docker Swarm Cluster Improvements
type: post
date: 2021-08-21T22:23:00Z
category:
  - Code
  - Docker
  - Ceph
---

> This post is part of a series.
>
> 1. [Docker Swarm with Ceph for cross-server files](/2019/02/docker-swarm-with-ceph/)
> 2. [Upgrading Ceph in Docker Swarm](/2019/07/upgrading-ceph-in-docker-swarm/)
> 3. Docker Swarm Cluster Improvements **(This Post)**

Since my [previous](/2019/02/docker-swarm-with-ceph/) [posts](/2019/07/upgrading-ceph-in-docker-swarm/) about running docker-swarm with ceph, I've been using this fairly extensively in production and made some changes to the setup that follows on from the previous posts.

### 1. Run ceph using docker-compose

The first main change was to start running ceph with [docker-compose](https://docs.docker.com/compose/) on the host nodes.

The main reason for this is to save me needing to look up the `docker run` commands if I wanted to recreate the containers (eg for updates).

Firstly, switch ceph into maintenance mode:
```
ceph osd set noout
```

And then stop and remove the old containers:

```
docker stop ceph-mds; docker stop ceph-osd; docker stop ceph-mon; docker stop ceph-mgr;
docker rm ceph-mds; docker rm ceph-osd; docker rm ceph-mon; docker rm ceph-mgr;
```

Install docker-compose following the [installation](https://docs.docker.com/compose/install/) guide, which looks something like this at the time of writing:

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
mv /usr/local/bin/docker-compose /usr/bin/docker-compose
```

And then create a new directory `/root/ceph/` with a `docker-compose.yml` file inside that looks something like this:

```yaml
---
version: '3.9'

x-ceph-default: &ceph-default
   image: 'ceph/daemon:latest-nautilus'
   restart: always
   network_mode: host
   pid: host
   volumes:
      - '/var/lib/ceph/:/var/lib/ceph/'
      - '/etc/ceph:/etc/ceph'

services:
   mds:
      << : *ceph-default
      command: mds
      container_name: ceph-mds
      environment:
         - CEPHFS_CREATE=1
         - CEPHFS_DATA_POOL_PG=128
         - CEPHFS_METADATA_POOL_PG=128

   osd-sdb:
      << : *ceph-default
      command: osd
      container_name: ceph-osd-sdb
      privileged: true
      volumes:
         - '/var/lib/ceph/:/var/lib/ceph/'
         - '/etc/ceph:/etc/ceph'
         - '/dev/:/dev/'
      environment:
         - OSD_DEVICE=/dev/sdb
         - OSD_TYPE=disk

   mgr:
      << : *ceph-default
      command: mgr
      container_name: ceph-mgr
      privileged: true

   mon:
      << : *ceph-default
      command: mon
      container_name: ceph-mon
      environment:
         - MON_IP=<MON IP>
         - CEPH_PUBLIC_NETWORK=<PUBLIC NETWORK>
```

 - `<MON IP>` should be replaced with the output from `ip addr show dev eth0 | grep "inet " | head -n 1 | awk '{print $2}' | awk -F/ '{print $1}'`
 - `<PUBLIC NETWORK>` should be replaced with the output from `ip route show dev eth0 | grep link | grep -v 169.254.0.0 | awk '{print $1}'`

Then the ceph containers can be restarted using:

```sh
docker-compose up -d
```
This should be done on each node one at a time.

This makes updating easier as we can now just change the `ceph-default` section and then stop/start the containers. Eg the process to upgrade to `octopus` on each node:

Firstly, edit `docker-compose.yml` and change the image to be `ceph/daemon:latest-octopus`

Then on each node we can run `docker-compose pull` to pull down the new image, and we can run through the upgrade process, which is similar to how we did it [last time](/2019/07/upgrading-ceph-in-docker-swarm/) but this time we don't need to remember the right options for `docker run`.

Start by setting `noout`:

```sh
ceph osd set noout
```

On each node one at a time restart the mon containers
```sh
docker-compose stop mon; docker-compose up -d mon
```
and mgr:
```sh
docker-compose stop mgr; docker-compose up -d mgr
```
and osd:
```sh
docker-compose stop osd-sdb; docker-compose up -d osd-sdb
```
(As before, you want to wait until `ceph osd versions` shows the new osd coming back and `ceph status` looks happy before moving on)

Once all 3 are done, we can enable octopus-only features:
```sh
ceph osd require-osd-release octopus
```

Now the mds containers are a bit different:

Firstly we need to change `max_mds` to 1 if it’s not already (You can check using `ceph fs get cephfs | grep max_mds`):
```sh
ceph fs set cephfs max_mds 1
```

Now we should stop all the non-active MDSs. We can see the currently active MDS using: `ceph status | grep -i mds` and on the standby nodes we can do:
```sh
docker-compose stop mds;
```

Then we can restart the active mds:
```sh
docker-compose stop mds; docker-compose up -d mds
```

And once it appears as `active` within `ceph status` we can restart the standbys:

```sh
docker-compose up -d mds
```

At this point, the `max_mds` value can be reset if it was previously anything other than 1.

Now unset the noout flag:

```sh
ceph osd unset noout
```

We can also update our `crushmap` to `straw2`:

```sh
ceph osd getcrushmap -o backup-crushmap
ceph osd crush set-all-straw-buckets-to-straw2
```

(This creates a backup that we can restore if needed with `ceph osd setcrushmap -i backup-crushmap`)

And fix the `insecure global_id reclaim` warning:

```sh
ceph config set mon auth_allow_insecure_global_id_reclaim false
```

After making this change, our host node version of ceph may no longer be able to talk to the cluster, but this should be easily resolved by running `yum update ceph`

The upgrade process from `octopus` to `pacific` is much the same up to the point where we run `ceph osd unset noout` there are no post-upgrade cleanups needed.

### 2. Run keepalived via swarm

This is somewhat of a quality-of-life change to ensure that drained nodes don't have keepalived running.

I didn't previously document setting up keepalived on these nodes, but I've now switched from running it outside of swarm, to inside swarm.

A `docker-compose.yml` file similar to this:

```yaml
---
version: '3.7'

x-defaults: &defaults
  image: osixia/keepalived:2.0.20
  cap_add:
    - NET_ADMIN
  networks:
    - host
  volumes:
   - /var/data/composefiles/keepalived/fixPriority.sh:/container/run/startup/000-fixPriority.sh
  deploy:
    mode: global
    restart_policy:
      condition: any

services:

  v4:
    << : *defaults
    environment:
      - "KEEPALIVED_VIRTUAL_IPS=#PYTHON2BASH:['<IPV4 IP>/29']"
      - KEEPALIVED_UNICAST_PEERS=
      - KEEPALIVED_ROUTER_ID=204

  v6:
    << : *defaults
    environment:
      - "KEEPALIVED_VIRTUAL_IPS=#PYTHON2BASH:['<IPV6 IP>/64']"
      - KEEPALIVED_UNICAST_PEERS=
      - KEEPALIVED_ROUTER_ID=206

networks:
  host:
    external: true
```

 - `<IPV4 IP>` and `<IPV6 IP>` are the VIPs we want to use.

With `/var/data/composefiles/keepalived/fixPriority.sh` looking like:

```sh
#!/bin/sh

PRIORITY_FROM_IP=$((255 - $(ip addr show dev ${KEEPALIVED_INTERFACE-eth0} | grep "inet " | head -n 1 | awk '{print $2}' | awk -F/ '{print $1}' | awk -F. '{print $4}')))

if [ "${PRIORITY_FROM_IP}" != "" ]; then
        echo ${PRIORITY_FROM_IP} > /container/run/environment/KEEPALIVED_PRIORITY
fi;
```

Then this can be run similar to any other swarm service. The priorities are set based on the IPs of the host nodes.

We need to make sure that we have `modprobe ip_vs` run at startup, of which the easiest way is using `/etc/rc.d/rc.local`. On my clusters this looks something like:

```sh
touch /var/lock/subsys/local
modprobe ip_vs
sed -i '/'$(hostname)'/d' /etc/hosts
mount /var/data
```

And then `chmod a+x /etc/rc.d/rc.local`.

This also ensures our `/var/data` ceph mount is mounted, and removes the pointer to 127.0.0.1 for our hostname (which breaks our ceph mounting as we're using our public IPs).

### 3. Helper scripts

I have all my `docker-compose.yml` files for my different stacks/services live under `/var/data/composefiles/` in separate folders per stack.

To make (re-)running and debugging these easier, I have a helper script that is loaded into the bash profile of my host nodes that gives me a few useful commands:

`runstack` and `stopstack` in a directory under `/var/data/composefiles/` will start/stop the stack without needing to use the full `docker stack deploy ...` command.
`drain` and `undrain` on a node will drain it and pause/unpause ceph as appropriate to allow for updates/reboots.
`servicelogs` command to look at logs for a specific running instance of the service (because the `docker service logs` command is weird and mixes the logs from different nodes)
`serviceexec` command to easily jump into a specific running isntance of a container from any node (eg `serviceexec keepalived_v4 0 bash` to jump into the first running instance)


I have [this script](/2021/08/docker-swarm-cluster-improvements/swarm-helper.sh) at `/var/data/.bash_common` and then this gets synced over to `/root/.bash_common` periodically and then it gets loaded into the shell by adding:

```sh
if [ -f /root/.bash_common ]; then
        . /root/.bash_common
fi;
```

to the bottom of `/root/.bashrc`

(I used to load it directly from `/var/data/.bash_common` but this breaks the ability to login as root easily if there are issues with the ceph volume)
