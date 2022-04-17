#!/bin/sh
set -e

. ./vmconfig.sh

if [ ! -d ${VMPASSTHRU} ] ; then
echo "Cannot find passthrough directory" >&2
exit 1
fi

# requires a tun/tap device

# ip link add name br0 type bridge
# ip link dev br0 set up
# ip tuntap add tap7 mode tap
# ip link set tap7 up
# Bridge the adapter:
# ip link set tap7 master br0

qemu-system-x86_64 -name ${VMNAME} \
	-enable-kvm -machine q35 -cpu host -smp 2 \
	-nodefaults \
	-rtc base=utc \
	-vga qxl \
	-spice port=${VMSPICEPORT},addr=${VMSPICEIP},disable-ticketing \
	-bios /usr/share/edk2-ovmf/OVMF_CODE.fd \
	-m ${VMRAMMB} \
	-drive file=${VMIMAGENAME},format=${VMIMAGEFORMAT},if=virtio \
	-fsdev local,id=exp1,path=${VMPASSTHRU},security_model=passthrough \
	-device virtio-9p-pci,fsdev=exp1,mount_tag=host${VMNAME} \
	-device virtio-net-pci,netdev=${TAPDEV0},mac=02:ca:fe:d0:0d:01 \
	-netdev tap,id=${TAPDEV0},ifname=${TAPDEV0},script=no

