#!/bin/sh

set -e

trap cleanup EXIT

. /etc/init.d/tc-functions

. ./beeps-library

cleanup()
{
    echo "Powering off in 15 seconds..."
    kill %1 || echo -n "" # stop any background signals
    short_rapid_blasts &
    sleep 15
    kill %1 # stop short_rapid_blasts
    short_beep
    sudo poweroff
}

wait_for_pendrive_removal()
{
    while [ -e /dev/sda ]
    do
        sleep 1
    done
}

./check-target.sh

echo "${GREEN}Mounting payload partition...${NORMAL}"

sudo mount /dev/sda2 /mnt # PFDII_DATA partition

logfile="/mnt/$(date -u "+%Y-%m-%dT%H%M%S_UTC").log"

if [[ -r /mnt/log-to-file ]]
then
    sudo touch "${logfile}"
    sudo chmod 666 "${logfile}"
    echo "${BLUE}Logging to ${logfile}${NORMAL}"
    exec >> >(sudo tee "${logfile}") 2>&1
fi

if [[ -r /mnt/log-to-tcp ]]
then
    echo -n "${BLUE}"
    while IFS=: read log_host log_port
    do
        echo -n "Logging stderr and stdout to tcp $log_host:$log_port .."
        timeout 15 sh -c "while ! nslookup $log_host >/dev/null 2>&1; do sleep 2 ; echo -n . ; done"
        echo ""
        if [[ -r /mnt/log-to-file ]]
        then
            (tail -f "${logfile}" | nc $log_host $log_port >/dev/null) &
        else
            exec > >(tee >(nc $log_host $log_port >/dev/null)) 2>&1
        fi
        echo "Connected at $(date -Iseconds)"
    done < /mnt/log-to-tcp
    echo -n "${NORMAL}"
fi

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
sleep 3 # attention_signal is around 2s

echo "${MAGENTA}Infusing...${NORMAL}"
long_every_minute &

echo -n "${CYAN}"
src="/mnt/${img}"
dst=/dev/nvme0n1

progress_dd()
{
    total_size=$(ls -l "${src}" | awk '{ print $5 }')
    dd if="${src}" bs=4M \
        | pv --buffer-size 4096 --direct-io --name "${img}" --size "${total_size}" \
        | sudo dd of="${dst}" bs=4M conv=fsync
}

fast_dd()
{
    time sudo dd if="${src}" bs=4M of="${dst}" conv=fsync
}

#progress_dd   # 3-4 slower but with live progress info
fast_dd         # 3-4 faster but without any live progress info

echo -n "${NORMAL}"

# sudo umount /mnt  ## FIXME: logging is still in progress, should stop gracefully

echo "${MAGENTA}Done${NORMAL}"
kill %1 # stop long_every_minute

cleanup()
{
    kill %1 || echo -n "" # stop any background signals
}

long_two_short_every_minute &
echo "${BLUE}Remove pendrive to reboot...${NORMAL}"
echo "${BLUE}Or ctrl-c to stop the script and enter shell...${NORMAL}"
wait_for_pendrive_removal
kill %1 # stop long_two_short_every_minute
echo "${BLUE}**** Pendrive removed ****${NORMAL}"
echo "${BLUE}**** Will reboot in 2 seconds... ****${NORMAL}"
sleep 2
all_clear_signal
sudo reboot
