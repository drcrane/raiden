#!/bin/sh
set -x
set -e
. ./base_config.sh
if [ "X${VMIMAGEFMT}" == "Xqcow2" ] ; then
qemu-nbd --connect=${VMBLKDEV} --format=${VMIMAGEFMT} "${VMIMAGE}"
else
losetup --partscan ${VMBLKDEV} "${VMIMAGE}"
fi
if [ true ] ; then
echo -n "${VMPASSPHRASE}" |cryptsetup luksOpen ${VMBLKROOT} ${VMDMNAME} --key-file=-
mount ${VMMAPPERROOT} ${VMMOUNTPOINT}
else
mount ${VMBLKROOT} ${VMMOUNTPOINT}
fi
mount ${VMBLKBOOT} ${VMMOUNTPOINT}/boot
mount --bind /dev ${VMMOUNTPOINT}/dev
mount --bind /dev/pts ${VMMOUNTPOINT}/dev/pts
mount --bind /dev/shm ${VMMOUNTPOINT}/dev/shm
mount --bind /proc ${VMMOUNTPOINT}/proc
mount --bind /run ${VMMOUNTPOINT}/run
mount --bind /sys ${VMMOUNTPOINT}/sys

