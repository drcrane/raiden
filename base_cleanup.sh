#!/bin/sh
set -x
set -e

. ./base_config.sh

sync
umount -f ${VMMOUNTPOINT}/dev/pts 2>/dev/null || true
umount -f ${VMMOUNTPOINT}/dev/shm 2>/dev/null || true
umount -f ${VMMOUNTPOINT}/dev 2>/dev/null || true
umount -f ${VMMOUNTPOINT}/proc 2>/dev/null || true
umount -f ${VMMOUNTPOINT}/run 2>/dev/null || true
umount -f ${VMMOUNTPOINT}/sys 2>/dev/null || true
umount -f ${VMMOUNTPOINT}/boot || true
umount -f ${VMMOUNTPOINT} || true
swapoff ${VMBLKSWAP} || true

if [ "x${VMENCRYPTED}" == "xtrue" ] ; then
cryptsetup luksClose ${VMDMNAME} || true
fi

if [ "X${VMIMAGEFMT}" == "Xqcow2" ] ; then
qemu-nbd --disconnect ${VMBLKDEV} || true
else
losetup --detach ${VMBLKDEV} || true
fi
