#!/usr/bin/env bash

set -e
set -x

trap cleanup EXIT

qemu-img create disk.img 10G

disk_id=$(echo $(hdiutil attach -nomount disk.img))

function cleanup()
{
    hdiutil detach "${disk_id}"
}

diskutil partitionDisk "${disk_id}" 2 MBR fat32 "PFDII_BOOT" 36M ExFAT "PFDII_DATA" 0b
