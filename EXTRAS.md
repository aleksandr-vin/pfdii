# Extra things

## Resizing partition after infusion

Get the *resize2fs* tcz:

```shell
(cd /Volumes/PFDII_DATA/ && wget http://www.tinycorelinux.net/15.x/x86_64/tcz/e2fsprogs.tcz)
```

And add *post-dd.sh* script:

```sh
#!/bin/sh

set -e

set -x

script_dir=$(dirname $0)

TARGET_DEV=/dev/nvme0n1
TARGET_PART=4

echo "Resizing the /data partition"

tce-load -i "${script_dir}"/*.tcz

# Reread partition table
sudo hdparm -z "${TARGET_DEV}"

sleep 3

# Check the file system
sudo e2fsck -p -f "${TARGET_DEV}p${TARGET_PART}" || echo -n ""

# Resize the file system
sudo resize2fs -p "${TARGET_DEV}p${TARGET_PART}"

# Calculate the new end of the partition (assuming you want to extend it to the end of the disk)
# Replace 100% with the desired size if you want a specific size
new_end=$(sudo fdisk -l "${TARGET_DEV}" | grep Disk | awk '{print $3}')

# Resize the partition
sudo fdisk "${TARGET_DEV}" <<EOF
d
4
n
p
4

$new_end
w
EOF

# Check the partition table
sudo fdisk -l "${TARGET_DEV}"
```
