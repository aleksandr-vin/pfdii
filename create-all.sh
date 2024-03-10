#!/usr/bin/env bash

set -e
set -x

trap cleanup EXIT

# Creating disk file

qemu-img create disk.img 10G

disk_id=$(hdiutil attach -nomount disk.img | awk '{ print $1 }')

function cleanup()
{
    hdiutil detach "${disk_id}"
}

# Creating 2 partitions: ESP (created by default) and exFAT

diskutil partitionDisk "${disk_id}" 1 GPT  ExFAT "PFDII_DATA" 0b

# Downloading Tiny Core Linux

[[ -f CorePure64.iso ]] || wget http://www.tinycorelinux.net/15.x/x86_64/release/CorePure64-15.0.iso -O CorePure64.iso

read core_disk_id core_disk_mount <<< $(hdiutil attach CorePure64.iso)

function cleanup()
{
    hdiutil detach "${core_disk_id}"
    hdiutil detach "${disk_id}"
}

# Installing EFI bootloader (syslinux)

ESP_mount=$(pwd)/ESP-mount

mkdir -p "${ESP_mount}"

mount -t msdos "${disk_id}s1" "${ESP_mount}"

mkdir -p "${ESP_mount}/EFI/BOOT/"

## Configuring syslinux

cat > "${ESP_mount}/EFI/BOOT/syslinux.cfg" <<EOF
DEFAULT vmlinuz
LABEL vmlinuz
    KERNEL ../../vmlinuz64
    INITRD ../../corepure64.gz
    APPEND nodhcp nozswap noswap ro noautonet
EOF
#### Remove `quiet` kernel option if need debugging !

# Copying kernel and system

cp -v "${core_disk_mount}"/boot/{vmlinuz64,corepure64.gz} "${ESP_mount}/"

# Timestamping PFDII_DATA (mounted automatically by `diskutil partitionDisk`)

echo "Created at $(date)" > /Volumes/PFDII_DATA/created-at.txt

hdiutil unmount "${ESP_mount}"
hdiutil unmount /Volumes/PFDII_DATA

hdiutil detach "${core_disk_id}"    
hdiutil detach "${disk_id}"

function cleanup()
{
    echo "noop"
}

docker build --platform=linux/amd64 -f Dockerfile-syslinux -t pfdii-syslinux-installer .

docker run -it --privileged --rm --platform=linux/amd64 \
       -v $(pwd)/disk.img:/workspace/disk.img \
       pfdii-syslinux-installer

############# DONE ###############

if ! [[ -f OVMF.fd ]]
then
    docker build --platform=linux/amd64 -f Dockerfile-OVMF -t pfdii-ovmf .

    docker run --rm --platform=linux/amd64 \
       -v $(pwd):/out \
       pfdii-ovmf
fi

cat <<EOF
Done, you can try booting the image with:

  qemu-system-x86_64 -m 256M \\
    -bios OVMF.fd \\
    -drive file=disk.img,format=raw,index=0,media=disk \\
    -boot c

EOF
