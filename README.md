# Raiden

Scripted creation of a Virtual Machine to be finalised later with
packages and other configuration. The base OS for this VM is Alpine
Linux.

This is for a x86\_64 VM (`apk.static` is a static binary that should
execute on any x86\_64 linux machine).

This script makes an image using UEFI booting and GPT partition table
with syslinux.

See `base_getapk.sh`.

## Theory of Operation

These scripts create an Alpine Linux Virtual Machine image to be executed
by qemu.

To begin the host machine should have some utilities:

* `losetup`
* `sfdisk`
* `mkfs.ext4`
* `qemu-img`

The busybox `losetup` is not good enough for this script

See `base_build.sh` for details.

The various scripts should be executed in order:

`base_build.sh` will create an image, mount it in MOUNTPOINT and install
Alpine Linux onto it. The image will NOT be unmounted and files in the
new base layout can be edited.

`base_raiden.sh` installs raiden-specific packages and configuration.

`base_cleanup.sh` unmounts and detaches the image.

At this point the image has been created and can be executed with qemu.

## Host Share

The `9pnet_virtio` module must be installed in the kernel (add it to
`/etc/modules` to allow on-boot loading).

The `pt` directory is intended for 9p file sharing and can be mounted
on the guest like this:

    mount -t 9p -o trans=virtio,access=client,msize=4194304 hostshare /mnt/hostpt

Or in `/etc/fstab` like this:

    hostshare   /mnt/hostpt   9p  trans=virtio,rw 0   0

Delay for `_netdev`?

    hostshare   /mnt/hostpt   9p  trans=virtio,rw,_netdev 0   0

The section in the `vmstart` script is:

    -fsdev local,id=exp1,path=${VMPASSTHRU},security_model=passthrough \
    -device virtio-9p-pci,fsdev=exp1,mount_tag=hostshare

The user ids on the guest have the same permissions as those on the
host!

There may be a problem mounting the 9p net (have a look in dmesg) if
it fails. The modules that need to be loaded include:

    9p
    9pnet
    9pnet_virtio
    virtio_pci
    virtio_ring
    virtio

## Serial Interface and Guest Agent

There are some notes on e42.uk.

This creates an emulated serial interface that is detected by Alpine Linux for normal `/dev/ttySn`.

    -chardev pty,id=charserial0 \
    -device isa-serial,chardev=charserial0,id=serial0

The Fedora wiki expands on this with virtio serial ports, also waypipe might be able to use this.

## Shared Memory between Host and Guest

[SO Question](https://stackoverflow.com/questions/77675263/shared-memory-between-guest-and-host-in-qemu)

## NAT and QEMU Stuff (works on Arch)

Create a virtual network and forward ports from host to guest. Does this use IPTables?

    -device virtio-net-pci,netdev=netdev0,mac=${VMMACADDR0} \
    -netdev user,id=netdev0,net=192.168.76.0/24,dhcpstart=192.168.76.9,hostfwd=tcp::2022-:22,hostfwd=tcp::2443-:443,hostfwd=tcp::2080-:80

## VPN

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

`iptables` rules are easily broken, be careful about the exact path packets
take. To make this a little easier a default policy of DROP is recommended:

    iptables -t filter -P FORWARD DROP

The client IP address must be added to allow the packet to be processed by
the `POSTROUTING` chain in the `nat` table.

    iptables -t filter -A FORWARD --src 192.168.80.X/32 -j ACCEPT

## Using `qemu-nbd` and qcow2

Create a root image with a base backing file:

    mv root.img.raw base.img.raw
    qemu-img create -F raw -b base.img.raw -f qcow2 root.img.qcow2

This is incomplete and does not seem to be working as expected.

## VNC Port Forwarding

Use either `pfwd`:

    pfwd 0.0.0.0 6124 192.168.80.24 5900

Forward the port with `iptables`

    iptables -t nat -A PREROUTING --proto tcp --dport 6121 -j DNAT --to 192.168.80.21:5900

## Troubleshooting

Artix Linux current build of `qemu-system-x86_64` fails with SIGSEGV.
A chroot of Alpine Linux will work around this problem:

    curl -O -L https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-minirootfs-3.24.1-x86_64.tar.gz
    mkdir chroot
    cd chroot
    tar -xf ../alpine-minirootfs-3.24.1-x86_64.tar.gz
    cd ..
    ./chroot_mount.sh
    chroot chroot /bin/ash
    <<< setup /etc/resolv.conf, apk add qemu-system-x86_64 >>>
    ./chroot_umount.sh

## References (Credit)

This work is a rip-off from [builds.sr.ht](https://git.sr.ht/~sircmpwn/builds.sr.ht/tree/master/item/images/alpine)
with some small modifications which allow it to work on Gentoo and fit
my requirements.

* [Serial Interface Stuff on Fedora](https://fedoraproject.org/wiki/Features/VirtioSerial)
* [Guest Agent Stuff](https://github.com/qemus/qemu-host)
* [Linux Questions about 9p virtio Problem](https://www.linuxquestions.org/questions/slackware-14/qemu-virtio-9p-host-filesystem-passthrough-failure-in-slackware-current-13may2015-4175542608/)
* [WayPipe](https://gitlab.freedesktop.org/mstoeckl/waypipe/)
