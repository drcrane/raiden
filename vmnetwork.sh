#!/bin/sh

. ./vmconfig.sh

if [ "X${VMNETWORKLINK}" == 'Xbridged' ]; then

echo "Deleting ${VMTAPDEV0}"
#ip tuntap del ${VMTAPDEV0} mode tap
busybox tunctl -d ${VMTAPDEV0}
echo "Making ${VMTAPDEV0}"
#ip tuntap add ${VMTAPDEV0} mode tap
busybox tunctl -t ${VMTAPDEV0}
ip link set down dev ${VMTAPDEV0}

# For ethernet bridged mode
# Add this device to bridge
busybox brctl addif ${VMBRIDGEIF} ${VMTAPDEV0}

# Bring interface up (for Bridged and IP Routed mode)
echo "Bringing Interface up"
ip link set up dev ${VMTAPDEV0}

fi

if [ "X${VMNETWORKLINK}" == 'Xrouted' ]; then

# For IP routed mode
# Set guest IP to 192.168.80.$((${VMNUMBER}+50))
echo Deleting ${VMTAPDEV0}
#ip tuntap del ${VMTAPDEV0} mode tap
busybox tunctl -d ${VMTAPDEV0}
echo Making ${VMTAPDEV0}
#ip tuntap add ${VMTAPDEV0} mode tap
busybox tunctl -t ${VMTAPDEV0}
echo Bringing ${VMTAPDEV0} up
ip link set up dev ${VMTAPDEV0}
echo Adding IP Address 192.168.80.2
ip addr add 192.168.80.2/32 dev ${VMTAPDEV0}
echo "Deleting route to 192.168.80.${VMNUMBER}/32"
ip route del 192.168.80.${VMNUMBER}/32 dev ${VMTAPDEV0}
echo "Adding Route to 192.168.80.${VMNUMBER}/32"
ip route add 192.168.80.${VMNUMBER}/32 dev ${VMTAPDEV0}

fi

