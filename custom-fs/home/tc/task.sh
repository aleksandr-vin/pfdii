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

PFDII_DATA=/mnt/sda2

echo -n "${YELLOW}"
timeout 20 sh -c '
    echo -n "Waiting for /dev/sda2 to appear in /etc/fstab ...";
    until cat /etc/fstab | grep /dev/sda2 >/dev/null
    do
	sleep 1;
	echo -n ".";
    done;
    echo "";
'
echo -n "${NORMAL}"

mount "${PFDII_DATA?}" # mounting PFDII_DATA partition via /etc/fstab

[[ -r "${PFDII_DATA?}"/env ]] && source "${PFDII_DATA?}"/env

DELAY="${DELAY-5}"

if [[ "${WITH_SOUND-yes}" != "yes" ]]
then
    beep() {
        echo -n "" # Muting beeps
    }
fi

TARGET_DEVICE=${TARGET_DEVICE-/dev/nvme0n1}
export TARGET_DEVICE

./check-target.sh

logfile=""${PFDII_DATA?}"/$(date -u "+%Y-%m-%dT%H%M%S_UTC").log"

if [[ "${LOG_TO_FILE-no}" == "yes" ]]
then
    sudo touch "${logfile}"
    sudo chmod 666 "${logfile}"
    echo "${BLUE}Logging to ${logfile}${NORMAL}"
    exec >> >(sudo tee "${logfile}") 2>&1
fi

if [[ -r "${PFDII_DATA?}"/log-to-tcp ]]
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
    done < "${PFDII_DATA?}"/log-to-tcp
    echo -n "${NORMAL}"
fi

img=$(cd "${PFDII_DATA?}" && ls -1 *.img *.img.lz4 2>/dev/null || echo "")

if [[ "$img" == "" ]]
then
    echo "${RED}No image for infusion found!${NORMAL}"
    exit 1
fi

if echo $img | wc -l | grep -e '^ *1$' >/dev/null
then
    echo "${GREEN}Image for infusion: ${CYAN}${img}${NORMAL}"
else    
    echo "${RED}Too many/few images: $img${NORMAL}"
    exit 1
fi

[[ "${DELAY}" -ge 2 ]] && echo "${YELLOW}Waiting for ${DELAY} seconds before infusion...${NORMAL}"
[[ "${DELAY}" -ge 0 ]] && attention_signal
[[ "${DELAY}" -ge 2 ]] && sleep $(( ${DELAY} - 2 )) # attention_signal is around 2s

echo "${MAGENTA}Infusing...${NORMAL}"
long_every_minute & long_every_minute_pid=$!

echo -n "${CYAN}"
src=""${PFDII_DATA?}"/${img}"
dst="${TARGET_DEVICE?}"

fast_dd()
{
    echo -e "\n\n"
    # Move the cursor up 3 lines
    ( while (sleep 1 ; echo -ne "\033[3A" ; killall -USR1 dd 2>/dev/null)
    do
        echo -n ""  
    done ; echo -e "\n\n" ) &

    case "${src}" in
        *.img.lz4)
            lz4 ${LZ4_FLAGS} -c -d "${src}" | dd of="${dst}" ${DD_FLAGS- bs=4M conv=fsync}
            ;;
        *.img)
            dd if="${src}" of="${dst}" ${DD_FLAGS- bs=4M conv=fsync}
            ;;
    esac
}

fast_dd

echo -n "${NORMAL}"

# sudo umount "${PFDII_DATA?}"  ## FIXME: logging is still in progress, should stop gracefully

echo "${MAGENTA}Done${NORMAL}"
kill %1 # stop long_every_minute

cleanup()
{
    kill %1 || echo -n "" # stop any background signals
}

long_two_short_every_minute & long_two_short_every_minute_pid=$!

if [[ "${WAIT_FOR_PENDRIVE_REMOVAL-yes}" == "yes" ]]
then
    echo "${BLUE}Remove pendrive to reboot...${NORMAL}"
    echo "${BLUE}Or ctrl-c to stop the script and enter shell...${NORMAL}"
    wait_for_pendrive_removal
    echo "${BLUE}**** Pendrive removed ****${NORMAL}"
    kill "${long_two_short_every_minute_pid}" # stop long_two_short_every_minute
fi

case "${ON_COMPLETE-default}" in
    reboot)
	echo "${BLUE}**** Will reboot in 2 seconds... ****${NORMAL}"
	sleep 2
	all_clear_signal
	sudo reboot
	;;
    *)
	echo "${BLUE}**** Will poweroff in 2 seconds... ****${NORMAL}"
	sleep 2
	all_clear_signal
	sudo poweroff
	;;	
esac
