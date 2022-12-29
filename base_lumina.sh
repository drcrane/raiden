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

run_root apk add alpine-sdk
run_root apk add openvpn
echo 'tun' >> ${MOUNTPOINT}/etc/modules
cp etc/sysctl.d/ipv6.conf ${MOUNTPOINT}/etc/sysctl.d/
run_root chown root:root /etc/sysctl.d/ipv6.conf
run_root chmod 644 /etc/sysctl.d/ipv6.conf
