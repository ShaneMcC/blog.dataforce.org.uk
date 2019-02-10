---
title: HUGO PPA
author: Dataforce
url:  /2018/01/hugo-ppa/
image: hugo.png
description: Hugo PPA
type: post
date: 2018-01-08T09:39:47Z
category:
  - General
---

I run ubuntu on my servers, and since moving to Hugo, I wanted to make sure I was using the latest version available.

The ubuntu repos currently contain hugo version 0.15 in Xenial, and 0.25.1 in artful (And the next version, bionic only contains 0.26). The latest version of hugo (as of today) is currently 0.32.2 - so the main repos are quite a bit out of date.

So to work around this, I've setup an apt repo that tracks the latest release for hugo, which can be installed and used like so:

```shell
sudo wget http://packages.dataforce.org.uk/packages.dataforce.org.uk_hugo.list -O /etc/apt/sources.list.d/packages.dataforce.org.uk_hugo.list
wget -qO- http://packages.dataforce.org.uk/pubkey.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install hugo
```

This repo tracks the latest hugo debs in all 4 of the architectures supported: `amd64`, `i386`, `armhf` and `arm64` and should stay automatically up to date with the latest version.
