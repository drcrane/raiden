#!/bin/sh
set -x
set -e

. ./base_config.sh

# these are in util-linux on gentoo
which sfdisk
which losetup
which mkfs.ext4
which mkfs.vfat

which ssh-keygen

which qemu-img

if [ -f root.img.raw ] ; then
echo "found existing disk image, delete to continue" 1>&2
exit 1
fi

if [ ! -d ${MOUNTPOINT} ] ; then
echo "MOUNTPOINT ${MOUNTPOINT} required before execution" 1>&2
echo "(can change in config)" 1>&2
exit 1
fi

cleanup() {
sync
}

if [ ! -f id_ed25519.pub ] ; then
ssh-keygen -t ed25519 -f id_ed25519 -q -N ""
fi

qemu-img create -f raw root.img.raw 16G
trap cleanup EXIT

losetup ${LOOPDEV} root.img.raw

# Creating a GPT Partition Table
sfdisk --no-reread ${LOOPDEV} <<EOF
label:GPT
1M,256M,C12A7328-F81F-11D2-BA4B-00A0C93EC93B,*
,2048M,S
,,L
EOF

losetup --detach ${LOOPDEV}
losetup --partscan ${LOOPDEV} root.img.raw

mkfs.vfat -F 32 /dev/loop5p1
mkswap ${LOOPDEV}p2
mkfs.ext4 -O ^has_journal ${LOOPDEV}p3

mount ${LOOPDEV}p3 ${MOUNTPOINT}
mkdir ${MOUNTPOINT}/boot
mkdir ${MOUNTPOINT}/etc
cp /etc/resolv.conf ${MOUNTPOINT}/etc/
mount ${LOOPDEV}p1 ${MOUNTPOINT}/boot

run_root() {
	chroot ${MOUNTPOINT} /usr/bin/env \
		PATH=/sbin:/usr/sbin:/bin:/usr/bin \
		/bin/sh -c "$*"
}

./apk.static add --update-cache \
	--repository http://dl-cdn.alpinelinux.org/alpine/$release/main/ \
	--allow-untrusted \
	--arch="$arch" \
	--root=${MOUNTPOINT} \
	--initdb \
	acct alpine-base alpine-conf $linux

run_root setup-hostname -n ${hostname}
run_root setup-interfaces -i <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	hostname ${hostname}
	address ${hostip}
	netmask 255.255.255.255
	post-up ip route add ${defgateway} dev eth0
	post-up ip route add default via ${defgateway} dev eth0
EOF

run_root setup-dns -d example.org 74.82.42.42 23.253.163.53
run_root setup-timezone -z Europe/London
if [ "$release" = "edge" ]
then
	cat >${MOUNTPOINT}/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/$release/main
http://dl-cdn.alpinelinux.org/alpine/$release/community
http://dl-cdn.alpinelinux.org/alpine/$release/testing
EOF
else
	cat >${MOUNTPOINT}/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/$release/main
http://dl-cdn.alpinelinux.org/alpine/$release/community
EOF
fi
run_root setup-keymap gb gb

mount --bind /dev ${MOUNTPOINT}/dev
mount --bind /dev/pts ${MOUNTPOINT}/dev/pts
mount --bind /dev/shm ${MOUNTPOINT}/dev/shm
mount --bind /proc ${MOUNTPOINT}/proc
mount --bind /run ${MOUNTPOINT}/run
mount --bind /sys ${MOUNTPOINT}/sys

# don't execute the installation script for syslinux
run_root apk add --no-scripts syslinux
run_root dd if=/usr/share/syslinux/gptmbr.bin of=${LOOPDEV} bs=1 count=440
run_root extlinux -i /boot

mkdir -p ${MOUNTPOINT}/boot/EFI/BOOT/
cp ${MOUNTPOINT}/usr/share/syslinux/efi64/syslinux.efi ${MOUNTPOINT}/boot/EFI/BOOT/bootx64.efi
cp ${MOUNTPOINT}/usr/share/syslinux/efi64/ldlinux.e64 ${MOUNTPOINT}/boot/EFI/BOOT/ldlinux.e64

cat >${MOUNTPOINT}/boot/EFI/BOOT/syslinux.cfg <<EOF
DEFAULT linux
LABEL linux
	LINUX /vmlinuz-virt
	INITRD /initramfs-virt
	APPEND root=/dev/vda3 rw modules=sd-mod,usb-storage,ext4 quiet rootfstype=ext4
EOF

run_root apk add openssh haveged doas

run_root rc-update add sshd default
run_root rc-update add crond default
run_root rc-update add haveged default
run_root rc-update add local default
for i in hwclock modules sysctl hostname bootmisc networking syslog swap urandom
do
	run_root rc-update add $i boot
done
for i in mount-ro killprocs savecache
do
	run_root rc-update add $i shutdown
done

sed -e 's/#key_types_to_generate=""/key_types_to_generate="ed25519"/' -i ${MOUNTPOINT}/etc/conf.d/sshd
echo 'sshd_disable_keygen="yes"' >> ${MOUNTPOINT}/etc/conf.d/sshd

sed -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' \
	-e 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/' \
	-i ${MOUNTPOINT}/etc/ssh/sshd_config

if [ ! -f etc/ssh/ssh_host_ed25519_key ]; then
if [ ! -d etc/ssh ] ; then
mkdir -p etc/ssh
fi
ssh-keygen -t ed25519 -f etc/ssh/ssh_host_ed25519_key -q -N ""
fi
cp etc/ssh/ssh_host_ed25519_key ${MOUNTPOINT}/etc/ssh/
run_root chown root:root /etc/ssh/ssh_host_ed25519_key
chmod og-rw ${MOUNTPOINT}/etc/ssh/ssh_host_ed25519_key
cp etc/ssh/ssh_host_ed25519_key.pub ${MOUNTPOINT}/etc/ssh/
run_root chown root:root /etc/ssh/ssh_host_ed25519_key.pub

run_root mkdir /root/.ssh
run_root chmod go-rwx /root/.ssh
cat id_ed25519.pub >> ${MOUNTPOINT}/root/.ssh/authorized_keys
run_root adduser -u 1000 -D -h /home/${defusername} -s /bin/ash ${defusername}
run_root adduser ${defusername} wheel
run_root adduser ${defusername} kvm
run_root passwd -u ${defusername}

printf '%s\n' "permit nopass keepenv :wheel" >> ${MOUNTPOINT}/etc/doas.d/doas.conf
rm -f ${MOUNTPOINT}/etc/motd

cat >${MOUNTPOINT}/boot/extlinux.conf <<EOF
DEFAULT linux
LABEL linux
	LINUX vmlinuz-$(echo "$linux" | cut -d- -f2-)
	INITRD initramfs-$(echo "$linux" | cut -d- -f2-)
	APPEND root=/dev/vda3 rw modules=sd-mod,usb-storage,ext4 quiet rootfstype=ext4
EOF

# since the fs was created without a journal data=ordered will prevent mount
# /dev/vda1 /boot ext4 rw,relatime,data=ordered 0 0
# /dev/vda3 / ext4 rw,relatime,data=ordered 0 0

cat >>${MOUNTPOINT}/etc/fstab <<EOF
/dev/vda1 /boot ext4 rw,relatime 0 0
/dev/vda2 swap swap defaults 0 0
/dev/vda3 / ext4 rw,relatime 0 0
EOF

pkg_version() {
	name=$(run_root apk list $1 | grep installed | cut -d' ' -f1)
	echo ${name##$1-}
}

run_root apk add $linux=$(pkg_version $linux)

