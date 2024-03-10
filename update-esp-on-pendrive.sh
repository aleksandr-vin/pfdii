#!/usr/bin/env bash

set -e


disk_id=$(hdiutil attach -nomount disk.img | head -1 | awk '{ print $1 }')

function cleanup()
{
    hdiutil detach "${disk_id}"
}

TARGET_DEV_ESP=${1?Specify target dev with ESP as an argument}

case "${TARGET_DEV_ESP}" in
    *s1)
	;;
    *)
	echo "${TARGET_DEV_ESP} does not look like a dev pointing to a partition (should end with 's1')"
	exit 1
esac

set -x

sudo dd if="${disk_id}"s1 of="${TARGET_DEV_ESP}" bs=4M conv=sync status=progress
