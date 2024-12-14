#!/bin/bash

set -e

mount /dev/sda /mnt
for F in /dev /sys /dev/pts /proc; do mount -o bind {,/mnt}${F}; done

chroot /mnt sh -c "wget -O /tmp/convert.sh https://blog.dataforce.org.uk/2024/11/convert-lxc-container-to-vm/convert_script.sh && chmod a+x /tmp/convert.sh && /tmp/convert.sh"

if [ $? -eq 0 ]; then
    for F in /dev/pts; do umount /mnt${F}; sleep 5; done
    for F in /dev /sys /proc; do umount /mnt${F}; done
    umount /mnt
    reboot
fi;
