#!/usr/bin/env bash

set -e

set -x

hdiutil detach /Volumes/BOOTABLE || echo ok
hdiutil attach disk.img

(cd custom-fs && find . | cpio -o -H newc | gzip -2 > ../mods.gz)

cat /Volumes/BOOTABLE/core.gz \
    beep.gz \
    pv.gz \
    mods.gz \
    > /Volumes/BOOTABLE/my-core.gz

cat > /Volumes/BOOTABLE/syslinux/syslinux.cfg <<EOF
DEFAULT vmlinuz
LABEL vmlinuz
    KERNEL ../vmlinuz
    INITRD ../my-core.gz
    APPEND nodhcp nozswap noswap ro noautonet quiet
EOF
# Remove `quiet` kernel option if need debugging !

hdiutil detach /Volumes/BOOTABLE
