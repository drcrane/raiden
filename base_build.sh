#!/bin/sh
set -x
set -e

. ./base_config.sh

# these are in util-linux on gentoo
# apk add sfdisk losetup e2fsprogs
which sfdisk
which losetup
losetup --version |grep 'losetup from util-linux'
which mkfs.ext4
which mkfs.vfat
which ssh-keygen
which qemu-img
lsmod |grep loop
lsmod |grep vfat
if [ ! -f ./apk.static ] ; then echo "no apk.static" ; exit 1 ; fi

# Install ovmf
# apk add ovmf
# These lines will cause the script to fail if OVMF is not installed
ls /usr/share/OVMF/OVMF_CODE.fd
ls /usr/share/OVMF/OVMF_VARS.fd

if [ -f root.img.raw ] ; then
echo "found existing disk image, delete to continue" 1>&2
exit 1
fi

if [ ! -d ${VMMOUNTPOINT} ] ; then
echo "VMMOUNTPOINT ${VMMOUNTPOINT} required before execution" 1>&2
echo "(can change in config)" 1>&2
exit 1
fi

cleanup() {
sync
}

if [ ! -f id_ed25519.pub ] ; then
ssh-keygen -t ed25519 -f id_ed25519 -q -N "" -C "root@${hostname}"
fi

qemu-img create -f raw root.img.raw ${VMDISKSIZE}
trap cleanup EXIT

losetup ${VMBLKDEV} root.img.raw

# Creating a GPT Partition Table
sfdisk --no-reread ${VMBLKDEV} <<EOF
label:GPT
1M,256M,C12A7328-F81F-11D2-BA4B-00A0C93EC93B,*
,${VMSWAPSIZE},S
,,L
EOF

losetup --detach ${VMBLKDEV}
for i in $(seq 1 5); do
	sleep 0.$i
	losetup --partscan ${VMBLKDEV} root.img.raw && break
done

mkfs.vfat -F 32 ${VMBLKBOOT}
mkswap ${VMBLKSWAP}
if [ "x${VMENCRYPTED}" == "xtrue" ] ; then
echo -n "${VMPASSPHRASE}" |cryptsetup luksFormat ${VMBLKROOT} --key-file=-
echo -n "${VMPASSPHRASE}" |cryptsetup luksOpen ${VMBLKROOT} ${VMDMNAME} --key-file=-
mkfs.ext4 -O ^has_journal ${VMMAPPERROOT}
mount ${VMMAPPERROOT} ${VMMOUNTPOINT}
else
mkfs.ext4 -O ^has_journal ${VMBLKROOT}
mount ${VMBLKROOT} ${VMMOUNTPOINT}
fi

mkdir ${VMMOUNTPOINT}/boot
mkdir ${VMMOUNTPOINT}/etc
cp /etc/resolv.conf ${VMMOUNTPOINT}/etc/
mount ${VMBLKBOOT} ${VMMOUNTPOINT}/boot

run_root() {
	chroot ${VMMOUNTPOINT} /usr/bin/env \
		PATH=/sbin:/usr/sbin:/bin:/usr/bin \
		/bin/sh -c "$*"
}

# do this from host os since then we will cache alpine-base etc
mkdir -p "${VMMOUNTPOINT}/var/cache/apk"
mkdir -p "${VMMOUNTPOINT}/etc/apk"
sh -c 'cd '"${VMMOUNTPOINT}"'/etc/apk ; [ ! -d cache ] && ln -s ../../var/cache/apk cache'

# exit

./apk.static add --update-cache \
	--repository http://dl-cdn.alpinelinux.org/alpine/$release/main/ \
	--allow-untrusted \
	--arch="$arch" \
	--root=${VMMOUNTPOINT} \
	--initdb \
	acct alpine-base alpine-conf $linux

# do it here and the above packages will not be cached.
# run_root mkdir -p /var/cache/apk
# run_root mkdir -p /etc/apk
# run_root 'cd /etc/apk ; [ ! -d cache ] && ln -s ../../var/cache/apk cache'

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

# run_root setup-dns -d ${VMDNSDOMAIN} ${VMDNSSERVER0} ${VMDNSSERVER1}
# run_root setup-timezone -z ${VMTIMEZONE}

if [ "$release" = "edge" ]
then
	cat >${VMMOUNTPOINT}/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/$release/main
http://dl-cdn.alpinelinux.org/alpine/$release/community
http://dl-cdn.alpinelinux.org/alpine/$release/testing
EOF
else
	cat >${VMMOUNTPOINT}/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/$release/main
http://dl-cdn.alpinelinux.org/alpine/$release/community
EOF
fi
run_root setup-keymap gb gb

run_root setup-dns -d ${VMDNSDOMAIN} ${VMDNSSERVER0} ${VMDNSSERVER1}
run_root apk add tzdata
run_root setup-timezone -z ${VMTIMEZONE}

mount --bind /dev ${VMMOUNTPOINT}/dev
mount --bind /dev/pts ${VMMOUNTPOINT}/dev/pts
mount --bind /dev/shm ${VMMOUNTPOINT}/dev/shm
mount --bind /proc ${VMMOUNTPOINT}/proc
mount --bind /run ${VMMOUNTPOINT}/run
mount --bind /sys ${VMMOUNTPOINT}/sys

# don't execute the installation script for syslinux
run_root apk add --no-scripts syslinux
run_root dd if=/usr/share/syslinux/gptmbr.bin of=${VMBLKDEV} bs=1 count=440
run_root extlinux -i /boot

mkdir -p ${VMMOUNTPOINT}/boot/EFI/BOOT/
cp ${VMMOUNTPOINT}/usr/share/syslinux/efi64/syslinux.efi ${VMMOUNTPOINT}/boot/EFI/BOOT/bootx64.efi
cp ${VMMOUNTPOINT}/usr/share/syslinux/efi64/ldlinux.e64 ${VMMOUNTPOINT}/boot/EFI/BOOT/ldlinux.e64

cat >${VMMOUNTPOINT}/boot/EFI/BOOT/syslinux.cfg <<EOF
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
for i in hwclock modules sysctl hostname bootmisc networking syslog swap seedrng
do
	run_root rc-update add $i boot
done
for i in mount-ro killprocs savecache
do
	run_root rc-update add $i shutdown
done

sed -e 's/#key_types_to_generate=""/key_types_to_generate="ed25519"/' -i ${VMMOUNTPOINT}/etc/conf.d/sshd
echo 'sshd_disable_keygen="yes"' >> ${VMMOUNTPOINT}/etc/conf.d/sshd

#sed -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' \
sed -e 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/' \
	-i ${VMMOUNTPOINT}/etc/ssh/sshd_config

if [ ! -f etc/ssh/ssh_host_ed25519_key ]; then
if [ ! -d etc/ssh ] ; then
mkdir -p etc/ssh
fi
ssh-keygen -t ed25519 -f etc/ssh/ssh_host_ed25519_key -q -N ""
fi
cp etc/ssh/ssh_host_ed25519_key ${VMMOUNTPOINT}/etc/ssh/
run_root chown root:root /etc/ssh/ssh_host_ed25519_key
chmod og-rw ${VMMOUNTPOINT}/etc/ssh/ssh_host_ed25519_key
cp etc/ssh/ssh_host_ed25519_key.pub ${VMMOUNTPOINT}/etc/ssh/
run_root chown root:root /etc/ssh/ssh_host_ed25519_key.pub

run_root mkdir /root/.ssh
run_root chmod go-rwx /root/.ssh
cat id_ed25519.pub >> ${VMMOUNTPOINT}/root/.ssh/authorized_keys
run_root adduser -u ${defuserid} -G ${defusergroup} -D -h /home/${defusername} -s /bin/ash ${defusername}
run_root adduser ${defusername} wheel
run_root adduser ${defusername} kvm
run_root passwd -u ${defusername}
run_root mkdir -p /home/${defusername}/.ssh
cat id_ed25519.pub >> ${VMMOUNTPOINT}/home/${defusername}/.ssh/authorized_keys
run_root chmod go-rwx /home/${defusername}/.ssh
run_root chown -R ${defusername}:${defusergroup} /home/${defusername}/.ssh

printf '%s\n' "permit nopass keepenv :wheel" >> ${VMMOUNTPOINT}/etc/doas.d/doas.conf
rm -f ${VMMOUNTPOINT}/etc/motd

cat >${VMMOUNTPOINT}/boot/extlinux.conf <<EOF
DEFAULT linux
LABEL linux
	LINUX vmlinuz-$(echo "$linux" | cut -d- -f2-)
	INITRD initramfs-$(echo "$linux" | cut -d- -f2-)
EOF

if [ "x${VMENCRYPTED}" == "xfalse" ] ; then

cat >>${VMMOUNTPOINT}/boot/extlinux.conf <<EOF
	APPEND root=/dev/vda3 rw modules=sd-mod,usb-storage,ext4 quiet rootfstype=ext4
EOF

cat >>${VMMOUNTPOINT}/etc/fstab <<EOF
/dev/vda1 /boot ext4 rw,relatime 0 0
/dev/vda2 swap swap defaults 0 0
/dev/vda3 / ext4 rw,relatime 0 0
EOF

fi

# for encrypted root fs
if [ "x${VMENCRYPTED}" == "xtrue" ] ; then

cat >>${VMMOUNTPOINT}/boot/extlinux.conf <<EOF
	APPEND cryptdevice=/dev/vda3:${VMDMNAME} root=/dev/mapper/${VMDMNAME} rw modules=sd-mod,usb-storage,ext4 quiet rootfstype=ext4
EOF

cat >>${VMMOUNTPOINT}/etc/fstab <<EOF
/dev/vda1 /boot ext4 rw,relatime 0 0
/dev/vda2 swap swap defaults 0 0
/dev/mapper/encryptd / ext4 rw,relatime 0 0
EOF

fi

# since the fs was created without a journal data=ordered will prevent mount
# /dev/vda1 /boot ext4 rw,relatime,data=ordered 0 0
# /dev/vda3 / ext4 rw,relatime,data=ordered 0 0




rm ${VMMOUNTPOINT}/etc/passwd-
rm ${VMMOUNTPOINT}/etc/shadow-
rm ${VMMOUNTPOINT}/etc/group-

pkg_version() {
	name=$(run_root apk list $1 | grep installed | cut -d' ' -f1)
	echo ${name##$1-}
}

run_root apk add $linux=$(pkg_version $linux)

