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

run_root apk add chrony lvm2 drbd samba-dc krb5 samba-winbind-clients acl openldap-clients
run_root rc-update add chronyd default
run_root rc-update add lvm sysinit

run_root apk add openvpn
echo 'tun' >> ${MOUNTPOINT}/etc/modules
cp etc/openvpn/openvpn-${hostname}.conf ${MOUNTPOINT}/etc/openvpn
if [ -f etc/openvpn/static.key ] ; then
cp etc/openvpn/static.key ${MOUNTPOINT}/etc/openvpn/
else
run_root openvpn --genkey secret /etc/openvpn/static.key
cp ${MOUNTPOINT}/etc/openvpn/ etc/openvpn/static.key
fi

