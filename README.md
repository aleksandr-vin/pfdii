# Pendrive for disk image infusions

If we have an image and we need to provision it on hardware box many times, we do an autoloader.

See this [post](https://aleksandr.vin/2024/03/02/pendrive-for-disk-image-infusions.html) for now.

## TL;DR;

Create a pendrive image *disk.img*:

```bash
./create-all.sh
./build-tools.sh
./add-overlay.sh
```

Place an image for infusion (Tails for example) in the exFAT partition of the *disk.img*:

```bash
hdiutil attach disk.img
pushd /Volumes/PFDII_DATA
wget https://download.tails.net/tails/stable/tails-amd64-6.0/tails-amd64-6.0.img
popd
hdiutil detach /dev/disk7  # replace /dev/disk7 with your output from `hdiutil attach disk.img`
```

Create a target disk *target.img*, big enough to fit the infusion image:

```bash
qemu-img create target.img 6G
```

And run the virtual machine (check your sound is on):

```bash
qemu-system-x86_64 -m 128M \
    -drive file=disk.img,format=raw,index=0,media=disk \
    -boot c \
    -drive file=target.img,if=none,id=nvm \
    -device nvme,serial=deadbeef,drive=nvm \
    -display curses \
    -audiodev coreaudio,id=audio0 -machine pcspk-audiodev=audio0
```

## Configuring

Can be done using *env* file in */Volumes/PFDII_DATA/* with these options, for example:

```shell
DELAY=0
LOG_TO_FILE="yes"
WITH_SOUND="no"
WAIT_FOR_PENDRIVE_REMOVAL=no
ON_COMPLETE=poweroff # or reboot (default is poweroff)
TARGET_DEVICE="/dev/nvme0n1"
DD_FLAGS="bs=4M conv=fsync" # "bs=4M conv=fsync" are default
LZ4_FLAGS="-v"
```

## Post-dd script

Place a *post-dd.sh* in */Volumes/PFDII_DATA/* with custom code that will be executed after
`dd` is completed.

## Lz4-compressed images

Lz4-compressed images **.img.lz4* are automatically decompressed and *dd*-ed. They should save space for sparce images with empty space.

To compress the **.img* call:

```bash
lz4 -c golden.img > /Volumes/PFDII_PAYLOAD/golden.img.lz4
```

## Logging to TCP

When copying image for infusion, run locally:

```bash
while true ; do sleep 1 ; nc -l 8866 ; done
```

And use ngrok to forward port from the Internet:

```bash
ngrok tcp 8866
```

You should see a line like:

```
Forwarding                    tcp://5.tcp.eu.ngrok.io:19442 -> localhost:8866
```

Write `5.tcp.eu.ngrok.io:19442` into */Volumes/PFDII_DATA/log-to-tcp*:

```bash
cat > /Volumes/PFDII_DATA/log-to-tcp <<EOF
5.tcp.eu.ngrok.io:19442
EOF
```

This way, you'll see the output of pfdii at work, like:

```
Logging stderr and stdout to tcp 5.tcp.eu.ngrok.io:19442 ....
Connected at 2024-03-04T01:49:06+00:00
Image for infusion: tails-amd64-6.0.img
Waiting for 5 seconds before infusion...
Infusing...
339+1 records in
339+1 records out
1425014784 bytes (1.3GB) copied, 9.820562 seconds, 138.4MB/s
real	0m 9.89s
user	0m 0.05s
sys	0m 5.94s
Done
Remove pendrive to reboot...
Or ctrl-c to stop the script and enter shell...
```


## Real USB

**TBD**

In general, differnece is only in:

1. Calling `diskutil partitionDisk` on a real usb device
2. Copying FAT32 partition from *disk.img* in place of FAT32 partition on real usb device
3. Copying MBR from *disk.img* to real usb device
