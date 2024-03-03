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

## Real USB

**TBD**

In general, differnece is only in:

1. Calling `diskutil partitionDisk` on a real usb device
2. Copying FAT32 partition from *disk.img* in place of FAT32 partition on real usb device
3. Copying MBR from *disk.img* to real usb device
