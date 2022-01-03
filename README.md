Raiden
======

samba4 domain controller: scripted creation.

This is for a x86\_64 VM (`apk.static` is a static binary that should
execute on any x86\_64 linux machine).

Theory of Operation
-------------------

These scripts create an alpine linux virtual machine image to be executed
by qemu.

To begin the host machine should have some utilities:

* `losetup`
* `sfdisk`
* `mkfs.ext4`
* `qemu-img`

See `base_build.sh` for details.

The various scripts should be executed in order:

`base_build.sh` will create an image, mount it in MOUNTPOINT and install
Alpine Linux onto it.

`base_raiden.sh` installs raiden-specific packages and configuration.

`base_cleanup.sh` unmounts and detaches the image.

At this point the image has been created and can be executed with qemu.

