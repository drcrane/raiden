#!/bin/sh
set -e
set -x

# For most of this stuff to work the host must forward packets.
# configuration is system-wide and best with sysctl:
# sysctl -w net.ipv4.ip_forward=1
# can also be performed at runtime:
# echo 1 > /proc/sys/net/ipv4/ip_forward

. ./vmconfig.sh

ARGV1="$1"

echo "Deleting Rules..."

iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} --dst ${VMHOSTIP}/32 -j ACCEPT || true

set -- ${VMVPNSRV}
while [ -n "$1" ]
do
iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} --dst ${1}/32 -j ACCEPT || true
iptables -t nat -D POSTROUTING -o ${VMOUTIF} --src ${VMCLIIP}/32 --dst ${1}/32 -j MASQUERADE || true
iptables -t filter -D FORWARD --src ${VMCLIIP}/32 --dst ${1}/32 -j ACCEPT || true
iptables -t filter -D FORWARD --src ${1}/32 --dst ${VMCLIIP}/32 -j ACCEPT || true
shift
done
iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} -j DROP || true

iptables -t mangle -D PREROUTING -i ${VMTAPDEV0} --dst 0.0.0.0/0 -j ACCEPT || true
iptables -t nat -D POSTROUTING --src ${VMCLIIP}/32 -o $VMOUTIF -j MASQUERADE || true
iptables -t filter -D FORWARD --src ${VMCLIIP}/32 --dst 0.0.0.0/0 -j ACCEPT || true
iptables -t filter -D FORWARD --src 0.0.0.0/32 --dst ${VMCLIIP}/32 -j ACCEPT || true

echo "Rules Deleted."

allowall() {
echo "Allowing All..."
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} --dst 0.0.0.0/0 -j ACCEPT
iptables -t nat -A POSTROUTING --src ${VMCLIIP}/32 -o ${VMOUTIF} -j MASQUERADE
iptables -t filter -A FORWARD --src ${VMCLIIP}/32 --dst 0.0.0.0/0 -j ACCEPT
iptables -t filter -A FORWARD --src 0.0.0.0/32 --dst ${VMCLIIP}/32 -j ACCEPT
}

allowvpnonly() {
echo "Allowing VPN Only..."
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} --dst ${VMHOSTIP}/32 -j ACCEPT
set -- ${VMVPNSRV}
while [ -n "$1" ]
do
echo "Allowing ${1}..."
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} --dst ${1}/32 -j ACCEPT
iptables -t nat -A POSTROUTING -o ${VMOUTIF} --src ${VMCLIIP}/32 --dst ${1}/32 -j MASQUERADE
iptables -t filter -A FORWARD --src ${VMCLIIP}/32 --dst ${1}/32 -j ACCEPT
iptables -t filter -A FORWARD --src ${1}/32 --dst ${VMCLIIP}/32 -j ACCEPT
shift
done
iptables -t mangle -A PREROUTING -i ${VMTAPDEV0} -j DROP
}

echo "Adding Rules"

if [[ "X${ARGV1}" == "Xallowall" ]] ; then
allowall
elif [[ "X${ARGV1}" == "Xallowvpn" ]] ; then
allowvpnonly
elif [[ "X${ARGV1}" == "Xremoveall" ]] ; then
echo "Removed All Rules"
else
echo "None"
fi


