#!/bin/sh
set -x
set -e
BASELOC="${1}"
if [ -z "${BASELOC}" ] || [ ! -d "${BASELOC}" ] ; then
	echo "No base location specified" 1>&2
	exit 1
fi
umount "${BASELOC}/dev/pts"
umount "${BASELOC}/dev/shm"
umount "${BASELOC}/dev"
umount "${BASELOC}/proc"
umount "${BASELOC}/run"
umount "${BASELOC}/sys"

