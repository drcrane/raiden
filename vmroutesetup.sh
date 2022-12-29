#!/bin/sh
set -e
set -x

. ./vmconfig.sh

# For most of this stuff to work the host must forward packets.
# configuration is system-wide and best with sysctl:
# sysctl -w net.ipv4.ip_forward=1
# can also be performed at runtime:
# echo 1 > /proc/sys/net/ipv4/ip_forward

ARGV1=$1

echo "Deleting Rules..."

iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} --dst ${VMHOSTIP}/32 -j ACCEPT 2>/dev/null || true

set -- ${VMVPNSRV}
while [ -n "$1" ]
do
iptables -t mangle -D PREROUTING -i ${VMTAPDEV} --dst $1 -j ACCEPT 2>/dev/null || true
iptables -t nat -D POSTROUTING -o ${VMOUTIF} --src $CLIIP --dst $1 -j MASQUERADE 2>/dev/null || true
shift
done
iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} -j DROP 2>/dev/null || true

iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} --dst 0.0.0.0/0 -j ACCEPT 2>/dev/null || true
iptables -t nat -D POSTROUTING --src ${VMCLIIP} -o ${VMOUTIF} -j MASQUERADE 2>/dev/null || true

echo "Rules Deleted."

allowall() {
echo "Allowing All..."
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} --dst 0.0.0.0/0 -j ACCEPT
iptables -t nat -A POSTROUTING --src ${VMCLIIP}/32 -o ${VMOUTIF} -j MASQUERADE
}

allowvpnonly() {
echo "Allowing VPN Only..."
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} --dst ${VMHOSTIP}/32 -j ACCEPT
set -- ${VMVPNSRV}
while [ -n "$1" ]
do
iptables -t mangle -A PREROUTING -i $${VMTAPDEV0} --dst $1 -j ACCEPT
iptables -t nat -A POSTROUTING -o ${VMOUTIF0} --src ${VMCLIIP}/32 --dst $1 -j MASQUERADE
shift
done
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} -j DROP
}

echo "Adding Rules"

if [[ "X$ARGV1" == "Xallowall" ]] ; then
allowall
elif [[ "X$ARGV1" == "Xallowvpn" ]] ; then
allowvpnonly
elif [[ "X$ARGV1" == "Xremoveall" ]] ; then
echo "Removed All Rules"
else
echo "None"
fi


