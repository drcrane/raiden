#!/bin/sh
set -x
set -e
. ./base_config.sh
losetup --partscan ${LOOPDEV} root.img.raw
mount ${LOOPDEV}p3 ${MOUNTPOINT}
mount ${LOOPDEV}p1 ${MOUNTPOINT}/boot
mount --bind /dev ${MOUNTPOINT}/dev
mount --bind /dev/pts ${MOUNTPOINT}/dev/pts
mount --bind /dev/shm ${MOUNTPOINT}/dev/shm
mount --bind /proc ${MOUNTPOINT}/proc
mount --bind /run ${MOUNTPOINT}/run
mount --bind /sys ${MOUNTPOINT}/sys

