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

DST="/mnt/EFI/BOOT"
mkdir -p "${DST}"
cp -r /usr/lib/syslinux/efi64/* "${DST}"

# Placing syslinux.efi under fallback name instead of calling efibootmgr:
cp -r /usr/lib/syslinux/efi64/syslinux.efi "${DST}"/bootx64.efi

#efibootmgr --create --disk /dev/"${loop_dev:0:-2}" \
#	   --part 1 --loader /EFI/syslinux/syslinux.efi --label "Syslinux" --unicode

umount /mnt
