#!/usr/bin/env bash

set -e
set -x

trap cleanup EXIT

cleanup() {
    hdiutil detach /Volumes/PFDII_BOOT
    hdiutil detach /Volumes/Core
}

hdiutil detach /Volumes/PFDII_BOOT 2>/dev/null || echo -n ""
hdiutil detach /Volumes/Core 2>/dev/null || echo -n ""
hdiutil attach disk.img
hdiutil attach Core-current.iso

(cd custom-fs && find . | cpio -o -H newc | gzip -2 > ../pfdii.gz)

[[ -r /Volumes/PFDII_BOOT/pfdii-core.gz ]] && mv /Volumes/PFDII_BOOT/{pfdii-,}core.gz

cat /Volumes/Core/boot/core.gz \
    pfdii.gz \
    > /Volumes/PFDII_BOOT/core.gz # overwriting bytes in place

mv /Volumes/PFDII_BOOT/{,pfdii-}core.gz

cat > /Volumes/PFDII_BOOT/syslinux/syslinux.cfg <<EOF
DEFAULT vmlinuz
LABEL vmlinuz
    KERNEL ../vmlinuz
    INITRD ../pfdii-core.gz
    APPEND nozswap noswap ro quiet
EOF
# noautonet nodhcp
# Remove `quiet` kernel option if need debugging !


######### DONE ##########

cat <<EOF
Done, you can try it with:

  qemu-system-x86_64 -m 128M \\
    -drive file=disk.img,format=raw,index=0,media=disk \\
    -boot c \\
    -drive file=target-big.img,if=none,id=nvm \\
    -device nvme,serial=deadbeef,drive=nvm \\
    -display curses \\
    -audiodev coreaudio,id=audio0 -machine pcspk-audiodev=audio0

EOF
