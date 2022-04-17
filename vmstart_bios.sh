#!/bin/bash

. ./vmconfig.sh

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
	-spice port=$((5900+${VMNUMBER})),addr=127.0.0.1,disable-ticketing \
	-monitor tcp:127.0.0.1:$((6000+${VMNUMBER})),server,nowait \
	-net nic,model=virtio,macaddr=${MACADDR0} \
	-net tap,ifname=${TAPDEV0},script=no,downscript=no \
	-drive if=virtio,file=${VMIMAGENAME},format=${VMIMAGEFORMAT},discard=unmap \
	-fsdev local,id=exp2,path=hostshare,security_model=passthrough \
	-device virtio-9p-pci,fsdev=exp2,mount_tag=hostshare


