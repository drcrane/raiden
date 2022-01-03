#!/bin/sh
set -x
set -e

. ./base_config.sh

sync
umount -f ${MOUNTPOINT}/dev/pts 2>/dev/null || true
umount -f ${MOUNTPOINT}/dev/shm 2>/dev/null || true
umount -f ${MOUNTPOINT}/dev 2>/dev/null || true
umount -f ${MOUNTPOINT}/proc 2>/dev/null || true
umount -f ${MOUNTPOINT}/run 2>/dev/null || true
umount -f ${MOUNTPOINT}/sys 2>/dev/null || true
umount -f ${MOUNTPOINT}/boot || true
umount -f ${MOUNTPOINT} || true
swapoff ${LOOPDEV}p2 || true
losetup --detach ${LOOPDEV} || true

