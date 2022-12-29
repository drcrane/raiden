#!/bin/sh
set -e

. ./vmconfig.sh

if [ ! -d ${VMPASSTHRU} ] ; then
echo "Cannot find passthrough directory" >&2
exit 1
fi

qemu-system-x86_64 -name ${VMNAME} \
	-enable-kvm -machine q35 -cpu host -smp 2 \
	-nodefaults \
	-rtc base=utc \
	-vga virtio \
	-vnc ${VMVNCIP}:${VMNUMBER} \
	-drive if=pflash,format=raw,unit=0,readonly=on,file=OVMF_CODE.fd \
	-drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
	-m ${VMRAMMB} \
	-drive file=${VMIMAGENAME},format=${VMIMAGEFORMAT},if=virtio \
	-fsdev local,id=exp1,path=${VMPASSTHRU},security_model=passthrough \
	-device virtio-9p-pci,fsdev=exp1,mount_tag=host${VMNAME} \
	-device virtio-net-pci,netdev=${VMTAPDEV0},mac=${VMMACADDR0} \
	-netdev tap,id=${VMTAPDEV0},ifname=${VMTAPDEV0},script=no

