#!/bin/sh

set -e

trap cleanup EXIT

cleanup()
{
    echo "Powering off in 15 seconds..."
    sleep 15
    sudo poweroff
}

. /etc/init.d/tc-functions

. ./beeps-library

cleanup()
{
    echo "Powering off in 15 seconds..."
    man_overboard_signal
    sleep 15
    sudo poweroff
}

./check-target.sh

echo "${GREEN}Mounting payload partition...${NORMAL}"

sudo mount /dev/sda2 /mnt

img=$(cd /mnt && ls -1 *.img)

if echo $img | wc -l | grep -e '^ *1$' >/dev/null
then
    echo "${GREEN}Image for infusion: ${CYAN}${img}${NORMAL}"
else    
    echo "${RED}Too many images: $img${NORMAL}"
    exit 1
fi

echo "${YELLOW}Waiting for 5 seconds before infusion...${NORMAL}"
attention_signal
sleep 5

echo "${MAGENTA}Infusing...${NORMAL}"

echo -n "${CYAN}"
src="/mnt/${img}"
dst=/dev/nvme0n1
total_size=$(ls -l "${src}" | awk '{ print $5 }')
dd if="${src}" bs=4M \
    | pv --buffer-size 4096 --direct-io --name "${img}" --size "${total_size}" \
    | sudo dd of="${dst}" bs=4M # oflag=sync
echo -n "${NORMAL}"

echo "${GREEN}Done${NORMAL}"
all_clear_signal

cleanup()
{
    echo ""
}

echo "Powering off in 10 seconds..."
sleep 10

sudo poweroff
