#!/bin/sh

set -e

trap cleanup EXIT

. /etc/init.d/tc-functions

. ./beeps-library

cleanup()
{
    for bg_pid in \
        "${long_two_short_every_minute_pid}" \
        "${long_every_minute_pid}"
    do
        [[ "${bg_pid}" != "" ]] && kill "${bg_pid}" || echo -n ""
    done
    echo "Powering off in 15 seconds..."
    short_rapid_blasts & short_rapid_blasts_pid=$!
    sleep 15
    kill "${short_rapid_blasts_pid}"
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

echo "${GREEN}Mounting payload partition...${NORMAL}"

sudo mount /dev/sda2 /mnt # PFDII_DATA partition

[[ -r /mnt/env ]] && source /mnt/env

if [[ "${WITH_SOUND-yes}" != "yes" ]]
then
    beep() {
        echo -n "" # Muting beeps
    }
fi

TARGET_DEVICE=${TARGET_DEVICE-/dev/nvme0n1}
export TARGET_DEVICE

./check-target.sh

logfile="/mnt/$(date -u "+%Y-%m-%dT%H%M%S_UTC").log"

if [[ "${LOG_TO_FILE-no}" == "yes" ]]
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
        if [[ "${LOG_TO_FILE-no}" == "yes" ]]
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

[[ "${DELAY}" -ge 2 ]] && echo "${YELLOW}Waiting for ${DELAY} seconds before infusion...${NORMAL}"
[[ "${DELAY}" -ge 0 ]] && attention_signal
[[ "${DELAY}" -ge 2 ]] && sleep $(( ${DELAY} - 2 )) # attention_signal is around 2s

echo "${MAGENTA}Infusing...${NORMAL}"
long_every_minute & long_every_minute_pid=$!

echo -n "${CYAN}"
src="/mnt/${img}"
dst="${TARGET_DEVICE?}"

fast_dd()
{
    echo -e "\n\n"
    # Move the cursor up 3 lines
    ( while (sleep 1 ; echo -ne "\033[3A" ; killall -USR1 dd 2>/dev/null)
    do
        echo -n ""  
    done ; echo -e "\n\n" ) &

    dd if="${src}" bs=4M of="${dst}" conv=fsync
}

fast_dd

echo -n "${NORMAL}"

# sudo umount /mnt  ## FIXME: logging is still in progress, should stop gracefully

echo "${MAGENTA}Done${NORMAL}"
kill %1 # stop long_every_minute

cleanup()
{
    kill %1 || echo -n "" # stop any background signals
}

long_two_short_every_minute & long_two_short_every_minute_pid=$!
echo "${BLUE}Remove pendrive to reboot...${NORMAL}"
echo "${BLUE}Or ctrl-c to stop the script and enter shell...${NORMAL}"
wait_for_pendrive_removal
kill "${long_two_short_every_minute_pid}" # stop long_two_short_every_minute
echo "${BLUE}**** Pendrive removed ****${NORMAL}"
echo "${BLUE}**** Will reboot in 2 seconds... ****${NORMAL}"
sleep 2
all_clear_signal
sudo reboot
