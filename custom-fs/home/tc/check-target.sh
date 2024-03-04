#!/bin/sh

set -e

. /etc/init.d/tc-functions

TARGET_DEVICE=${TARGET_DEVICE?}

echo -n "${GREEN}Checking ${YELLOW}${TARGET_DEVICE?}${GREEN} ..${NORMAL}"

if cat /proc/partitions | grep "${TARGET_DEVICE#/dev/}" >/dev/null
then
    echo "${GREEN}. ok${NORMAL}"
    exit 0
else
    echo "${RED}. failed: No ${YELLOW}${TARGET_DEVICE?}${RED} device detected${NORMAL}"
    exit 1
fi
