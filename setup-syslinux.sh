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

# Placing syslinux.efi under loader.eif,
# see Rodsbooks' Secure Boot, http://www.rodsbooks.com/efi-bootloaders/secureboot.html#preloader.
#
cp /usr/lib/syslinux/efi64/syslinux.efi "${DST}"/loader.efi
cp /preloader-signed/{PreLoader,HashTool}.efi "${DST}"/
cp /preloader-signed/PreLoader.efi "${DST}"/bootx64.efi # make PreLoader the default one
cat <<EOF
#
#
#   At the first boot with Secure Boot enabled:
#
#   > 1. PreLoader should launch, but it will probably complain that it couldn't launch loader.efi.
#   >    It will then launch HashTool, which is the program that PreLoader uses to store information (hashes) on the programs you authorize.
#   > 2. In HashTool, select the Enroll Hash option.
#   > 3. Browse to EFI/syslinux and select the loader.efi program file. HashTool asks for confirmation; respond Yes.
#
#   More info on http://www.rodsbooks.com/efi-bootloaders/secureboot.html#preloader
#
#
EOF
#

umount /mnt
