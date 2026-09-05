#!/bin/sh
set -x
set -e
BASELOC=$1
if [ ! -d "$BASELOC" ] ;
	echo "No base location specified" 1>&2
	exit 1
fi
umount ${BASELOC}/dev
umount ${BASELOC}/dev/pts
umount ${BASELOC}/dev/shm
umount ${BASELOC}/proc
umount ${BASELOC}/run
umount ${BASELOC}/sys

