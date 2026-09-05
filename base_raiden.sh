#!/bin/sh
set -x
set -e

source ./base_config.sh

if [ "$(cat ${VMMOUNTPOINT}/etc/hostname)" != "${hostname}" ] ; then
echo "Seems the image is not mounted!" 1>&2
exit 1
fi

if [ ! -f "${VMMOUNTPOINT}/etc/alpine-release" ] ; then
echo "Seems the image is not mounted!" 1>&2
exit 1
fi

if [ ! -f "etc/local.d/01-${hostname}-firstboot.start" ] ; then
echo "could not find etc/local.d/01-${hostname}-firstboot.start" 1>&2
exit 1
fi

run_root() {
	chroot "${VMMOUNTPOINT}" /usr/bin/env \
		PATH=/sbin:/usr/sbin:/bin:/usr/bin \
		/bin/sh -c "$*"
}

#mkdir -p "${VMMOUNTPOINT}/mnt/hostsdd2"
#echo 'hostsdd2   /mnt/hostsdd2   9p  trans=virtio,rw  0 0' >> "${VMMOUNTPOINT}/etc/fstab"

echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> "${VMMOUNTPOINT}/etc/apk/repositories"
#run_root apk add tcc musl-dev tcc-libs-static
run_root apk add build-base

cat >${VMMOUNTPOINT}/root/autologin.c <<EOF
#include <unistd.h>

int main(void) {
    execlp( "login", "login", "-f", "${defusername}", (char *)0);
}
EOF
#run_root 'cd /root && tcc -o autologin autologin.c && mv autologin /usr/sbin'
run_root 'cd /root && gcc -o autologin autologin.c && mv autologin /usr/sbin'
# Autologin for tty1 only (make who a bit cleaner)
sed -i 's@tty1::respawn:/sbin/getty@tty1::respawn:/sbin/getty -n -l /usr/sbin/autologin@g' "${VMMOUNTPOINT}/etc/inittab"
# Autologin for all ttys
#sed -i 's@:respawn:/sbin/getty@:respawn:/sbin/getty -n -l /usr/sbin/autologin@g' "${VMMOUNTPOINT}/etc/inittab"
#run_root apk del tcc musl-dev tcc-libs-static

rm "${VMMOUNTPOINT}/etc/profile.d/color_prompt.sh.disabled"
cp etc/profile.d/colour_prompt.sh "${VMMOUNTPOINT}/etc/profile.d/colour_prompt.sh"

# See also setup-utmps in firstboot.start
run_root apk add utmps

run_root apk add tmux ncurses-terminfo

run_root adduser ${defusername} video
run_root adduser ${defusername} input
run_root chown -R ${defusername}:${defusergroup} /home/${defusername}

run_root rc-update add local default
cp etc/local.d/01-${hostname}-firstboot.start "${VMMOUNTPOINT}/etc/local.d/"
run_root chmod a+x /etc/local.d/01-${hostname}-firstboot.start

