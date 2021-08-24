---
title: "Docker Swarm with Ceph for cross-server files"
author: Dataforce
url:  /2019/02/docker-swarm-with-ceph/
image: swarm.png
description: Docker Swarm Cluster with Ceph for cross-server files
type: post
date: 2019-02-10T21:36:54Z
category:
  - Code
  - Docker
  - Ceph
---

> This post is part of a series.
>
> 1. Docker Swarm with Ceph for cross-server files **(This Post)**
> 2. [Upgrading Ceph in Docker Swarm](/2019/07/upgrading-ceph-in-docker-swarm/)
> 3. [Docker Swarm Cluster Improvements](/2021/08/docker-swarm-cluster-improvements/)

I've been wanting to play with Docker Swarm for a while now for hosting containers, and finally sat down this weekend to do it.

Something that has always stopped me before now was that I wanted to have some kind of cross-site storage but I don't have any kind of SAN storage available to me just standalone hosts. I've been able to work around this using ceph on the nodes.

**Note:** I've never used ceph before, I don't really know what I'm doing with ceph, so this is all a bit of guesswork. I used [Funky Penguin's Geek Cookbook](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/shared-storage-ceph/) as a basis for some of this, though some things have changed since then, and I'm using base-centOS not AtomicHost (I tried AtomicHost, but wanted a newer-version of docker so switched away).

All my physical servers run [Proxmox](https://www.proxmox.com/en/), and this is no exception. On 3 of these host nodes I created a new VM (1 per node) to be part of the cluster. These all have 3 disks, 1 for the base OS, 1 for Ceph, 1 for cloud-init (The non-cloud-init disks are all SCSI with individual iothreads).

CentOS provide a cloud-image compatible disk [here](https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2) that I use as the base-os. I created a disk in proxmox, then detached it and overwrote it with the centos-provided image and re-attached it. I could have used an [Ubuntu](https://cloud-images.ubuntu.com/) cloud-image instead.

I now had 3 empty CentOS VMs ready to go.

First thing to do, is get the nodes ready for docker:

```shell
curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
mkdir /etc/docker
echo '{"storage-driver": "overlay2"}' > /etc/docker/daemon.json
yum install docker-ce
systemctl start chronyd
systemctl enable chronyd
systemctl start docker
systemctl enable docker
```

And build our swarm cluster.

On the first node:
```shell
docker swarm init
docker swarm join-token manager
```

And then on the other 2 nodes, copy and paste the output from the last command to join to the cluster. This joins all 3 nodes as managers, and you can confirm the cluster is working like so:
```shell
[root@ds-2 ~]# docker node ls
ID                            HOSTNAME                         STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
fo6paibeunoo9sulaiqu3iuqu     ds-1.dev.shanemcc.net            Ready               Active              Leader              18.09.1
phoy6ju7ait1aew7yifiemaob *   ds-2.dev.shanemcc.net            Ready               Active              Reachable           18.09.1
eexahtaiza1saibeishu8quie     ds-3.dev.shanemcc.net            Ready               Active              Reachable           18.09.1
[root@ds-2 ~]#
```

And all 3 host nodes have SSH keys generated (`ssh-keygen -t ed25519`) and setup within /root/.ssh/authorized_keys on each node so that I can ssh between them.

> **Note:** This section is out of date now.
> I would suggest deploying a newer version of ceph, and I now recommend deploying ceph using docker-compose as per [this post](/2021/08/docker-swarm-cluster-improvements/)
>
> I've not tested this, but you *should* be able to deploy the docker-compose file from that post and start the containers from that instead of using the `docker run` commands below (with the exception of the one to zap the OSD)

Now we can start setting up ceph.

Even though we will be running ceph within docker containers, I've also installed the ceph tools on the host node for convenience:

```shell
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://download.ceph.com/rpm-luminous/el7/noarch/ceph-release-1-1.el7.noarch.rpm
yum install ceph
```

Remove any old ceph that may be lying around:
```shell
rm -Rfv /etc/ceph
rm -Rfv /var/lib/ceph
mkdir /etc/ceph
mkdir /var/lib/ceph
chcon -Rt svirt_sandbox_file_t /etc/ceph
chcon -Rt svirt_sandbox_file_t /var/lib/ceph
```

On the first node, initialise a ceph monitor:

```shell
docker run -d --net=host --restart always -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ \
-e MON_IP=$(ip addr show dev eth0 | grep "inet " | head -n 1 | awk '{print $2}' | awk -F/ '{print $1}') \
-e CEPH_PUBLIC_NETWORK=$(ip route show dev eth0 | grep link | grep -v 169.254.0.0 | awk '{print $1}') \
--name="ceph-mon" ceph/daemon mon
```

And then copy the generated data over to the other 2 nodes:

```shell
scp -r /etc/ceph/* ds-2:/etc/ceph/
scp -r /etc/ceph/* ds-3:/etc/ceph/
```

And start the monitor on those also using the same command again.

Now, on all 3 nodes we can start a manager:

```shell
docker run -d --net=host --privileged=true --pid=host -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ --name="ceph-mgr" --restart=always ceph/daemon mgr
```

And create the OSDs on all 3 nodes (This will remove all the data from the disk provided (`/dev/sdb`) so be careful. The disk is given twice here):

```shell
ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring
docker run --rm --privileged=true -v /dev/:/dev/ -e OSD_DEVICE=/dev/sdb ceph/daemon zap_device
docker run -d --net=host --privileged=true --pid=host -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ -v /dev/:/dev/ -e OSD_DEVICE=/dev/sdb -e OSD_TYPE=disk --name="ceph-osd" --restart=always ceph/daemon osd
```

Once the OSDs are finished initialising on each node (watch `docker logs -f ceph-osd`), we can create the MDSs on each node:
```shell
docker run -d --net=host --name ceph-mds --restart always -v /var/lib/ceph/:/var/lib/ceph/ -v /etc/ceph:/etc/ceph -e CEPHFS_CREATE=1 -e CEPHFS_DATA_POOL_PG=128 -e CEPHFS_METADATA_POOL_PG=128 ceph/daemon mds
```

And then once these are created, lets tell ceph how many copies of things to keep:

```shell
ceph osd pool set cephfs_data size 3
ceph osd pool set cephfs_metadata size 3
```

And there's no point scrubbing on VM disks:
```shell
ceph osd set noscrub
ceph osd set nodeep-scrub
```

Now, we have a 3-node ceph cluster set up and we can mount it into the hosts. Each host will mount from itself:

```shell
mkdir /var/data
ceph auth get-or-create client.dockerswarm osd 'allow rw' mon 'allow r' mds 'allow' > /etc/ceph/keyring.dockerswarm
echo "$(hostname -s):6789:/      /var/data/      ceph      name=dockerswarm,secret=$(ceph-authtool /etc/ceph/keyring.dockerswarm -p -n client.dockerswarm),noatime,_netdev,context=system_u:object_r:svirt_sandbox_file_t:s0 0 2" >> /etc/fstab
mount -a
```

> **Note:**
> There are also some recommendations in [this post](/2019/07/upgrading-ceph-in-docker-swarm/) to mount ceph from multiple nodes not just the local node.

All 3 hosts should now have a `/var/data` directory and files that are created on one should appear automatically on the others.

For my use-case so far, this is sufficient. I'm using files/directories within /var/data as bind mounts (not volumes) in my docker containers currently and it seems to be working. I'm planning on playing about more with this in the coming weeks to see how well it works with more real-world usage.
