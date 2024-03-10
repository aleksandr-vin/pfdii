# Extra things

## Resizing partition after infusion

Get the *resize2fs* tcz:

```shell
(cd /Volumes/PFDII_DATA/ && wget http://www.tinycorelinux.net/15.x/x86_64/tcz/e2fsprogs.tcz)
```

And add *post-dd.sh* script:

```sh
#!/bin/sh

script_dir=$(dirname $0)

echo "Resizing the /data partition"
tce-load -i "${script_dir}"/e2fsprogs.tcz

...
```
