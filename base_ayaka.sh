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

run_root mkdir -p /opt/bin
cp opt/bin/infrarecv.sh ${MOUNTPOINT}/opt/bin/
run_root chown root:root ${MOUNTPOINT}/opt/bin/infrarecv.sh
run_root chmod 700 ${MOUNTPOINT}/opt/bin/infrarecv.sh

if [ ! -f "${defusername}_id_ed25519" ] ; then
ssh-keygen -t ed25519 -f ${defusername}_id_ed25519 -C "${defusername}@${hostname}" -q -N ""
fi
mkdir ${MOUNTPOINT}/home/${defusername}/.ssh
cp ${defusername}_id_ed25519 ${MOUNTPOINT}/home/${defusername}/.ssh/id_ed25519
cp ${defusername}_id_ed25519.pub ${MOUNTPOINT}/home/${defusername}/.ssh/id_ed25519.pub
run_root chown -R ${defusername}:users /home/${defusername}/.ssh
run_root chmod og-rx /home/${defusername}/.ssh
run_root chmod 600 /home/${defusername}/.ssh/id_ed25519
run_root chmod 644 /home/${defusername}/.ssh/id_ed25519.pub

run_root apk add git

