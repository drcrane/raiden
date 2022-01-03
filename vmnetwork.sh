#!/bin/sh

. ./vmconfig.sh

if [[ "X$NETWORKLINK" == 'Xbridged' ]]; then

echo "Deleting ${TAPDEV0}"
#ip tuntap del ${TAPDEV0} mode tap
busybox tunctl -d ${TAPDEV0}
echo "Making ${TAPDEV0}"
#ip tuntap add ${TAPDEV0} mode tap
busybox tunctl -t ${TAPDEV0}
ip link set down dev ${TAPDEV0}

# For ethernet bridged mode
# Add this device to bridge
busybox brctl addif ${BRIDGEIF} ${TAPDEV0}

# Bring interface up (for Bridged and IP Routed mode)
echo "Bringing Interface up"
ip link set up dev ${TAPDEV0}

fi

if [[ "X$NETWORKLINK" == 'Xrouted' ]]; then

# For IP routed mode
# Set guest IP to 192.168.80.$((${NUMBER}+50))
echo Deleting ${TAPDEV0}
#ip tuntap del ${TAPDEV0} mode tap
busybox tunctl -d ${TAPDEV0}
echo Making ${TAPDEV0}
#ip tuntap add ${TAPDEV0} mode tap
busybox tunctl -t ${TAPDEV0}
echo Bringing ${TAPDEV0} up
ip link set up dev ${TAPDEV0}
echo Adding IP Address 192.168.80.2
ip addr add 192.168.80.2/32 dev ${TAPDEV0}
echo "Deleting route to 192.168.80.$(((${NUMBER})))/32"
ip route del 192.168.80.$((${NUMBER}))/32 dev ${TAPDEV0}
echo "Adding Route to 192.168.80.$(((${NUMBER})))/32"
ip route add 192.168.80.$((${NUMBER}))/32 dev ${TAPDEV0}

fi

