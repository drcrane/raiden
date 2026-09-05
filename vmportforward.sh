#!/bin/sh
. ./vmconfig.sh
iptables -t nat -A PREROUTING ! --src ${VMCLIIP} --proto tcp --dport 22${VMNUMBER} -j DNAT --to ${VMCLIIP}:22

