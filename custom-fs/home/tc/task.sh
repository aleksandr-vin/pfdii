#!/bin/sh

set -e

. /etc/init.d/tc-functions

./check-target.sh

echo "${GREEN}Mounting payload partition...${NORMAL}"

sudo mount /dev/sda1 /mnt

echo "${MAGENTA}Infusing...${NORMAL}"

echo -n "${CYAN}"
img=tails-amd64-6.0.img
src="/mnt/${img}"
dst=/dev/nvme0n1
total_size=$(ls -l "${src}" | awk '{ print $5 }')
dd if="${src}" bs=4M \
    | /pv --buffer-size 4096 --direct-io --name "${img}" --size "${total_size}" \
    | sudo dd of="${dst}" bs=4M # oflag=sync
echo -n "${NORMAL}"

echo "${GREEN}Done${NORMAL}"

sleep 10

sudo poweroff
