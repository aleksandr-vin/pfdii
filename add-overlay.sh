#!/usr/bin/env bash

set -e

set -x

hdiutil attach disk.img

(cd custom-fs && find . | cpio -o -H newc | gzip -2 > ../mods.gz)

cat /Volumes/BOOTABLE/core.gz beep.gz mods.gz > /Volumes/BOOTABLE/my-core.gz

cat > /Volumes/BOOTABLE/syslinux/syslinux.cfg <<EOF
DEFAULT vmlinuz
LABEL vmlinuz
    KERNEL ../vmlinuz
    INITRD ../my-core.gz
    APPEND nodhcp nozswap noswap ro
EOF

hdiutil detach /Volumes/BOOTABLE
