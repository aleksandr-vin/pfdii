# Pendrive for disk image infusions

If we have an image and we need to provision it on hardware box many times, we do an autoloader.

See this [post](https://aleksandr.vin/2024/03/02/pendrive-for-disk-image-infusions.html) for now.


To run qemu with NVMe drive (target):

```bash
qemu-system-x86_64 -m 512M \
  -drive file=disk.img,format=raw,index=0,media=disk \
  -boot c \
  -drive file=target.img,if=none,id=nvm \
  -device nvme,serial=deadbeef,drive=nvm
```

Use ncurses:

```
-display curses
```
