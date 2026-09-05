#!/bin/ash

. ./vmconfig.sh

echo "Starting ${VMNAME} on ${VMNUMBER}"

qemu-system-x86_64 -enable-kvm \
	-name ${VMNAME} \
	-k en-gb \
	-m ${VMRAMMB} \
	-cpu host \
	-machine q35 \
	-nodefaults \
	-smp 2 \
	-rtc base=utc \
	-vga qxl \
	-spice port=${VMSPICEPORT},addr=${VMSPICEIP},disable-ticketing=on \
	-monitor tcp:127.0.0.1:$((6000+${VMNUMBER})),server,nowait \
	-net nic,model=virtio,macaddr=${VMMACADDR0} \
	-net tap,ifname=${VMTAPDEV0},script=no,downscript=no \
	-drive if=virtio,file=${VMIMAGENAME},format=${VMIMAGEFORMAT},discard=unmap \
	-fsdev local,id=exp2,path=${VMPASSTHRU},security_model=passthrough \
	-device virtio-9p-pci,fsdev=exp2,mount_tag=host${VMNAME} \
	-serial tcp:localhost:${VMSERIAL},server=on,wait=off


