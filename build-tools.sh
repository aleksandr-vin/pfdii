#!/usr/bin/env bash

set -x
set -e

# Building syslinux installer Docker image

docker build --platform=linux/amd64 -f Dockerfile-tools-builder -t pfdii-tools-builder .

## Building beep 

wget http://www.johnath.com/beep/beep-1.3.tar.gz
tar zxvf beep-1.3.tar.gz

docker run --rm -it -v $(pwd)/beep-1.3:/code --platform=linux/amd64 pfdii-tools-builder \
       gcc -m32 --static -o beep beep.c

cp beep-1.3/beep custom-fs/bin/
