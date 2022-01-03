#!/bin/sh
set -x
set -e

. ./base_config.sh

if [ ! -f ${MOUNTPOINT}/etc/alpine-release ] ; then
echo "Seems the image is not mounted!" 1>&2
exit 1
fi

run_root() {
	chroot ${MOUNTPOINT} /usr/bin/env \
		PATH=/sbin:/usr/sbin:/bin:/usr/bin \
		/bin/sh -c "$*"
}

run_root apk add chrony lvm2 drbd samba
run_root rc-update add chronyd default
run_root rc-update add lvm sysinit

