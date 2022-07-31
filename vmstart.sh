#!/bin/sh
set -e

. ./vmconfig.sh

if [ ! -d ${VMPASSTHRU} ] ; then
echo "Cannot find passthrough directory" >&2
exit 1
fi

echo To connect with spice:
echo spicy --host=${VMSPICEIP} --port=${VMSPICEPORT}

qemu-system-x86_64 -name ${VMNAME} \
	-enable-kvm -machine q35 -cpu host -smp 2 \
	-nodefaults \
	-rtc base=utc \
	-vga qxl \
	-spice port=${VMSPICEPORT},addr=${VMSPICEIP},disable-ticketing=on \
	-bios /usr/share/edk2-ovmf/OVMF_CODE.fd \
	-m ${VMRAMMB} \
	-drive file=${VMIMAGENAME},format=${VMIMAGEFORMAT},if=virtio \
	-fsdev local,id=exp1,path=${VMPASSTHRU},security_model=passthrough \
	-device virtio-9p-pci,fsdev=exp1,mount_tag=host${VMNAME} \
	-device virtio-net-pci,netdev=${TAPDEV0},mac=02:ca:fe:d0:0d:01 \
	-netdev tap,id=${TAPDEV0},ifname=${TAPDEV0},script=no

