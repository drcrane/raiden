#!/bin/sh
set -x
set -e

. ./base_config.sh

if [ ! -f ${VMMOUNTPOINT}/etc/alpine-release ] ; then
echo "Seems the image is not mounted!" 1>&2
exit 1
fi

run_root() {
	chroot ${VMMOUNTPOINT} /usr/bin/env \
		PATH=/sbin:/usr/sbin:/bin:/usr/bin \
		/bin/sh -c "$*"
}

run_root apk add docker

