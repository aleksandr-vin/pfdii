#!/bin/sh

set -e

. /etc/init.d/tc-functions

echo "${GREEN}Checking...${NORMAL}"

if cat /proc/partitions | grep nvme0n1 >/dev/null
then
    echo "${YELLOW}Target system detected${NORMAL}"
    exit 0
else
    echo "${RED}No ${YELLOW}nvme0n1${RED} device detected${NORMAL}"
    exit 1
fi
