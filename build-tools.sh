#!/usr/bin/env bash

set -x
set -e

# Building syslinux installer Docker image

docker build --platform=linux/amd64 -f Dockerfile-tools-builder -t pfdii-tools-builder .

## Building beep 

[[ -r beep-1.3.tar.gz ]] || wget http://www.johnath.com/beep/beep-1.3.tar.gz
tar zxvf beep-1.3.tar.gz

docker run --rm -it -v $(pwd)/beep-1.3:/code --platform=linux/amd64 pfdii-tools-builder \
       gcc -m32 --static -o beep beep.c

cp beep-1.3/beep custom-fs/bin/

## Building lz4

# see http://tinycorelinux.net/14.x/x86_64/tcz/src/lz4/compile_liblz4

[[ -r lz4-1.9.4.tar.gz ]] || wget https://github.com/lz4/lz4/archive/refs/tags/v1.9.4.tar.gz -O lz4-1.9.4.tar.gz

tar zxvf lz4-1.9.4.tar.gz

docker run --rm -it -v $(pwd)/lz4-1.9.4:/code --platform=linux/amd64 pfdii-tools-builder \
       sh -c "make clean; CFLAGS='-m32 --static' make -j"

cp lz4-1.9.4/lz4 custom-fs/bin/

## Building gparted

git clone https://gitlab.gnome.org/GNOME/gparted.git

docker run --rm -it -v $(pwd)/gparted:/code --platform=linux/amd64 pfdii-tools-builder \
       sh -c "./autogen.sh && make clean; CFLAGS='-m32 --static' make -j"
