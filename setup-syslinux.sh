#!/usr/bin/env bash
#
# Usage:
#
#   docker build --platform=linux/amd64 -f Dockerfile-syslinux -t pfdii-syslinux-installer .
#
#   docker run -it --privileged --rm --platform=linux/amd64 \
#          -v $(pwd)/disk.img:/workspace/disk.img \
#          -pfdii-syslinux-installer
#

set -x
set -e

trap cleanup EXIT

function cleanup()
{
    kpartx -dv /workspace/disk.img
}

loop_dev=$(kpartx -av /workspace/disk.img | head -1 | awk '{ print $3 }')

if [[ -z "${loop_dev}" ]]
then
    exit 1
fi

# losetup -l  # to list loop mappings

mount "/dev/mapper/${loop_dev}" /mnt

extlinux --install /mnt/syslinux

dd bs=440 count=1 conv=notrunc oflag=sync if=/usr/lib/syslinux/bios/mbr.bin of=/dev/"${loop_dev:0:-2}"

umount /mnt
