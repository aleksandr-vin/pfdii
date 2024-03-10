#!/usr/bin/env bash

set -e
set -x

trap cleanup EXIT

cleanup() {
    hdiutil detach /Volumes/Core
}

hdiutil detach /Volumes/Core 2>/dev/null || echo -n ""
hdiutil attach Core-current.iso

disk_id=$(hdiutil attach -nomount disk.img | head -1 | awk '{ print $1 }')

function cleanup()
{
    hdiutil detach "${disk_id}"
    hdiutil detach /Volumes/Core
}

ESP_mount=$(pwd)/ESP-mount

mount -t msdos "${disk_id}s1" "${ESP_mount}"

(cd custom-fs && find . | cpio -o -H newc | gzip -2 > ../pfdii.gz)

[[ -r "${ESP_mount}"/pfdii-core.gz ]] && mv "${ESP_mount}"/{pfdii-,}core.gz

cat /Volumes/Core/boot/core.gz \
    pfdii.gz \
    > "${ESP_mount}"/core.gz # overwriting bytes in place

mv "${ESP_mount}"/{,pfdii-}core.gz

cat > "${ESP_mount}"/EFI/BOOT/syslinux.cfg <<EOF
DEFAULT vmlinuz
LABEL vmlinuz
    KERNEL ../../vmlinuz
    INITRD ../../pfdii-core.gz
    APPEND nozswap noswap ro quiet
EOF
# noautonet nodhcp
# Remove `quiet` kernel option if need debugging !

echo "Showing sizes of init ramdisk:"
find "${ESP_mount}" -name '*.gz' -ls

######### DONE ##########

cat <<EOF
Done, you can try it with:

  qemu-system-x86_64 -m 148M \\
    -bios OVMF.fd \\
    -drive file=disk.img,format=raw,index=0,media=disk \\
    -boot c \\
    -drive file=target-big.img,format=raw,if=none,id=nvm \\
    -device nvme,serial=deadbeef,drive=nvm \\
    -audiodev coreaudio,id=audio0 -machine pcspk-audiodev=audio0

EOF
