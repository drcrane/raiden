#!/bin/sh
set -e

if [ ! -f OVMF_VARS.fd ] ; then
	if [ -f /usr/share/OVMF/OVMF_VARS.fd ] ; then
		cp /usr/share/OVMF/OVMF_VARS.fd .
	fi
fi

source ./vmconfig.sh

echo "Starting ${VMNAME} on ${VMNUMBER}"

if [ ! -d ${VMPASSTHRU} ] ; then
echo "Cannot find passthrough directory (${VMPASSTHRU})" >&2
exit 1
fi

VM_OVMF_CODE=OVMF_CODE.fd
VM_OVMF_VARS=OVMF_VARS.fd

exec qemu-system-x86_64 -name ${VMNAME} \
	-accel kvm \
	-machine q35 \
	-cpu host \
	-smp 2 \
	-nodefaults \
	-rtc base=utc \
	-vga virtio \
	${VMDISPLAY} \
	-m ${VMRAMMB} \
	-drive if=pflash,format=raw,unit=0,readonly=on,file=${VM_OVMF_CODE} \
	-drive if=pflash,format=raw,unit=1,file=${VM_OVMF_VARS} \
	-drive file=${VMIMAGENAME},format=${VMIMAGEFORMAT},if=virtio \
	-fsdev local,id=exp1,path=${VMPASSTHRU},security_model=passthrough \
	-device virtio-9p-pci,fsdev=exp1,mount_tag=host${VMNAME} \
	-device virtio-net-pci,netdev=${VMTAPDEV0},mac=${VMMACADDR0} \
	-netdev tap,id=${VMTAPDEV0},ifname=${VMTAPDEV0},script=no \
	-serial tcp:localhost:${VMSERIAL},server=on,wait=off

