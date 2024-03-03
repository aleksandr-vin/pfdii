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

# Creating 2 partitions (FAT32 and exFAT)

diskutil partitionDisk "${disk_id}" 2 MBR fat32 "PFDII_BOOT" 36M ExFAT "PFDII_DATA" 0b

# Downloading Tiny Core Linux

[[ -f Core-current.iso ]] || wget http://tinycorelinux.net/15.x/x86/release/Core-current.iso

read core_disk_id core_disk_mount <<< $(hdiutil attach Core-current.iso)

function cleanup()
{
    hdiutil detach "${core_disk_id}"    
    hdiutil detach "${disk_id}"
}

# Copying kernel and system

cp -v "${core_disk_mount}"/boot/{vmlinuz,core.gz} /Volumes/PFDII_BOOT/

# Installing bootloader

## Configuring syslinux

mkdir /Volumes/PFDII_BOOT/syslinux
cat > /Volumes/PFDII_BOOT/syslinux/syslinux.cfg <<EOF
DEFAULT vmlinuz
LABEL vmlinuz
    KERNEL ../vmlinuz
    INITRD ../core.gz
    APPEND nodhcp nozswap noswap ro noautonet quiet
EOF
#### Remove `quiet` kernel option if need debugging !

echo "Created at $(date)" > /Volumes/PFDII_DATA/hello.txt

hdiutil unmount /Volumes/PFDII_BOOT
hdiutil unmount /Volumes/PFDII_DATA

## Making vfat partition active

fdisk -e "${disk_id}" <<EOF
p
f 1
p
w
q
EOF

hdiutil detach "${core_disk_id}"    
hdiutil detach "${disk_id}"

function cleanup()
{
    echo "noop"
}

### Building syslinux installer Docker image

docker build --platform=linux/amd64 -f Dockerfile-syslinux -t pfdii-syslinux-installer .

## Installing extlinux and MBR

docker run -it --privileged --rm --platform=linux/amd64 \
       -v $(pwd)/disk.img:/workspace/disk.img \
       pfdii-syslinux-installer

############# DONE ###############

cat <<EOF
Done, you can try booting the image with:

  qemu-system-x86_64 -m 128M \\
    -drive file=disk.img,format=raw,index=0,media=disk \\
    -boot c \\
    -display curses

EOF
