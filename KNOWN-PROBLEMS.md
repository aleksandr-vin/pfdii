# Known Problems

## Missing support for vfat filesystem

Docker Desktop before version 4.27.1 has a bug and *setup-syslinux.sh* will fail complaining
about unknown 'vfat' filesystem.

## EFI Secure Boot

At the first boot with Secure Boot enabled:

> 1. PreLoader should launch, but it will probably complain that it couldn't launch loader.efi.
>    It will then launch HashTool, which is the program that PreLoader uses to store information (hashes) on the programs you authorize.
> 2. In HashTool, select the Enroll Hash option.
> 3. Browse to EFI/syslinux and select the loader.efi program file. HashTool asks for confirmation; respond Yes.

More info on http://www.rodsbooks.com/efi-bootloaders/secureboot.html#preloader
