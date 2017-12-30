---
title: 'Update iptables on Endian  Community Firewall (EFW) 2.4.0'
author: Dataforce
type: post
date: 2012-02-12T09:37:18+00:00
url: /2012/02/update-iptables-on-endian-community-firewall-efw-2-4-0/
category:
  - Endian
  - General
  - IPv6

---
Compiling ip6tables on Endian Community Firewall (EFW) 2.4.0

Unfortunately the version of ip6tables available at the time of fedora core 3 doesn't support the 'state' or 'comment' modules for use with firewall rules. So in order to get these, I decided to compile iptables 1.4.12.2 for Endian.

To do this, we'll need a build environment on the Endian box, we'll also install wget.

{{< prettify shell >}}
cd /root
rpm -Uvh --nodeps http://archives.fedoraproject.org/pub/archive/fedora/linux/core/3/i386/os/Fedora/RPMS/wget-1.9.1-17.i386.rpm
wget http://sourceforge.net/projects/efw/files/Development/EFW-2.4-RESPIN/EFW-COMMUNITY-2.4-devel-srpms.tar.gz/download -O EFW-COMMUNITY-2.4-devel-srpms.tar.gz
tar -xvf EFW-COMMUNITY-2.4-devel-srpms.tar.gz
cd EFW-COMMUNITY-2.4-201006071652/RPMS/
rpm -Uvh gcc-* binutils-* cpp-* glibc-extras-* glibc-*headers-* glibc-devel-* libgomp-* libstdc++-devel-* make-* rpm-build-* patch-*
{{< /prettify >}}

Now, we can compile iptables.

<!-- Old Method:

mkdir -p /usr/src/endian/{SOURCES,BUILD,RPMS}
cd /usr/src/endian/
rpm -Uvh /root/EFW-COMMUNITY-2.4-201006071652/RPMS/kernel-smp-devel-2.6.9-55.0.6.EL.endian22.i386.rpm
rpm -i /root/EFW-COMMUNITY-2.4-201006071652/SRPMS/iptables-1.4.0-1.endian16.src.rpm

wget http://netfilter.org/projects/iptables/files/iptables-1.4.12.2.tar.bz2 -O /usr/src/endian/SOURCES/iptables-1.4.12.2.tar.bz2
wget http://www.linuximq.net/patchs/iptables-1.4.12-IMQ-test4.diff -O /usr/src/endian/SOURCES/iptables-1.4.12-IMQ-test4.diff
sed -i 's/%define build_devel 1/%define build_devel 0/g' /usr/src/endian/SPECS/iptables.spec
sed -i 's/kernel-devel/kernel-smp-devel/g' /usr/src/endian/SPECS/iptables.spec
sed -i 's/Version: 1.4.0/Version: 1.4.12.2/g' /usr/src/endian/SPECS/iptables.spec
sed -ri 's/^(.*patch[0146].*)$/#\1/ig' /usr/src/endian/SPECS/iptables.spec
sed -ri 's/^(.*patch[5][^0-9].*)$/#\1/ig' /usr/src/endian/SPECS/iptables.spec
sed -ri 's/^(.*patch50[01].*)$/#\1/ig' /usr/src/endian/SPECS/iptables.spec
sed -i 's/iptables-1.4.0-imq.diff/iptables-1.4.12-IMQ-test4.diff/g' /usr/src/endian/SPECS/iptables.spec
sed -i 's#%build#%build\n./configure --enable-devel --libdir=/%{_lib} --prefix=%{_prefix} --sbindir=/sbin --bindir=/sbin --mandir=%{_mandir}#g' /usr/src/endian/SPECS/iptables.spec
sed -i 's#iptables-\*.8#iptables/iptables-\*.8#g' /usr/src/endian/SPECS/iptables.spec
sed -i 's#%{_lib}/iptables#%{_lib}/xtables#g' /usr/src/endian/SPECS/iptables.spec
sed -ri 's#^(make install .*)$#\1\nrm -Rf %{buildroot}/lib/pkgconfig/#' /usr/src/endian/SPECS/iptables.spec
sed -ri 's#^(%files)$#\1\n/%{_lib}/libip4tc.*\n/%{_lib}/libiptc.*\n/%{_lib}/libxtables.*\n/sbin/xtables-multi\n%{_includedir}/libiptc/ipt_kernel_headers.h\n%{_includedir}/libiptc/libiptc.h\n%{_includedir}/libiptc/libxtc.h\n%{_includedir}/xtables.h\n%{_mandir}/man8/iptables*\n%{_mandir}/man1/iptables*#g' /usr/src/endian/SPECS/iptables.spec
sed -ri 's#^(%files ipv6)$#\1\n/%{_lib}/libip6tc.*\n%{_includedir}/libiptc/libip6tc.h#g' /usr/src/endian/SPECS/iptables.spec
rpmbuild -bb /usr/src/endian/SPECS/iptables.spec

rpm -Uvh /usr/src/endian/RPMS/i386/iptables-1.4.12.2-1.endian16.i386.rpm  /usr/src/endian/RPMS/i386/iptables-ipv6-1.4.12.2-1.endian16.i386.rpm
-->


So firstly, lets download and install the sources we will need:

{{< prettify shell >}}
wget http://download.fedora.redhat.com/pub/fedora/linux/releases/16/Fedora/source/SRPMS/iptables-1.4.12-2.fc16.src.rpm
mkdir -p /usr/src/endian/{SOURCES,BUILD,RPMS}
wget http://www.linuximq.net/patchs/iptables-1.4.12-IMQ-test4.diff -O /usr/src/endian/SOURCES/iptables-1.4.12-IMQ-test4.diff
rpm --nomd5 -i iptables-1.4.12-2.fc16.src.rpm
{{< /prettify >}}

And modify the spec file to make it compile on Endian:

{{< prettify shell >}}
egrep -vi "(SOURCE[12]|ip6?tables-config|ip6?tables.init|ip6?tables.service)" /usr/src/endian/SPECS/iptables.spec > /usr/src/endian/SPECS/iptables.spec.temp
mv /usr/src/endian/SPECS/iptables.spec.temp /usr/src/endian/SPECS/iptables.spec
sed -i 's#CFLAGS=#export RPM_OPT_FLAGS=`echo $RPM_OPT_FLAGS | sed s/-mtune=generic//`\nCFLAGS=#g' /usr/src/endian/SPECS/iptables.spec
sed -i 's#rm -f include/linux/types.h##g' /usr/src/endian/SPECS/iptables.spec
sed -ri 's#^(Patch5:.*)$#\1\nPatch502: iptables-1.4.12-IMQ-test4.diff#g' /usr/src/endian/SPECS/iptables.spec
sed -ri 's#^(%patch5.*)$#\1\n%patch502 -p1#g' /usr/src/endian/SPECS/iptables.spec
rpmbuild --nodeps -bb /usr/src/endian/SPECS/iptables.spec
{{< /prettify >}}

And then install it:

{{< prettify shell >}}
rpm --nodeps -Uvh /usr/src/endian/RPMS/i386/iptables-1.4.12.2-1.i386.rpm
{{< /prettify >}}

now iptables and ip6tables will be version 1.4.12.2, and ip6tables will have the extra missing modules.

If anyone wants a copy of the generated RPM just leave a message here and I'll get them uploaded somewhere.
