Raiden
======

samba4 domain controller: scripted creation.

This is for a x86\_64 VM (`apk.static` is a static binary that should
execute on any x86\_64 linux machine).

This script makes an image using UEFI booting and GPT partition table
with syslinux.

Theory of Operation
-------------------

These scripts create an Alpine Linux Virtual Machine image to be executed
by qemu.

To begin the host machine should have some utilities:

* `losetup`
* `sfdisk`
* `mkfs.ext4`
* `qemu-img`

See `base_build.sh` for details.

The various scripts should be executed in order:

`base_build.sh` will create an image, mount it in MOUNTPOINT and install
Alpine Linux onto it. The image will NOT be unmounted and files in the
new base layout can be edited.

`base_raiden.sh` installs raiden-specific packages and configuration.

`base_cleanup.sh` unmounts and detaches the image.

At this point the image has been created and can be executed with qemu.

VPN
---

The `vmconfig.sh` and `vmroutesetup.sh` file contain support that restricts
communication to specific IP addresses (ipv4) this can be used to isolate
the machine from the local network.

    +-------------------+
    | Guest             |
    | eth0 192.168.80.X | - Interface connected to host machine
    +-------------------+

    +-------------------+
    | Host Machine      |
    | tapX 192.168.80.2 | - Interface connected to guest (routed)
    | eth0 192.168.1.10 | - Local Network with Access to Internet
    |                   |
    | iptables filter   |
    +-------------------+

`iptables` rules are easily broken be careful about the exact path packets
take. To make this a little easier a default policy of DROP is recommended.

    iptables -t filter -P FORWARD DROP

The client IP address must be added to allow the packet to be processed by
the `POSTROUTING` chain in the `nat` table.

    iptables -t filter -A FORWARD --src 192.168.80.X/32 -j ACCEPT

References (Credit)
-------------------

This work is a rip-off from [builds.sr.ht](https://git.sr.ht/~sircmpwn/builds.sr.ht/tree/master/item/images/alpine)
with some small modifications which allow it to work on Gentoo and fit
my requirements.

