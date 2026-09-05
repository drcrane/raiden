#!/bin/sh
set -x
set -e
BASELOC="${1}"
if [ -z "${BASELOC}" ] || [ ! -d "${BASELOC}" ] ; then
	echo "No base location specified" 1>&2
	exit 1
fi
mount --bind /dev ${BASELOC}/dev
mount --bind /dev/pts ${BASELOC}/dev/pts
mount --bind /dev/shm ${BASELOC}/dev/shm
mount -t proc proc ${BASELOC}/proc
mount --bind /run ${BASELOC}/run
mount -t sysfs sysfs ${BASELOC}/sys

