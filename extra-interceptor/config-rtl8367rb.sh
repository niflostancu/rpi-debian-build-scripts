#!/bin/sh

# rtl8367rb has 7 ports
# port 0 is the cpu port
# ports 1-4 are the gigabit ethernet ports
# ports 6-7 are the expansion rgmii ports

swconfig dev rtl8367rb set reset
swconfig dev rtl8367rb set enable_vlan 1
swconfig dev rtl8367rb vlan 1 set ports "0t 1"
swconfig dev rtl8367rb vlan 2 set ports "0t 2 3 4"

# setup 8 vlans for each expansion port
# for p in 0 1 2 3 4 5 6 7; do
#   swconfig dev rtl8367rb vlan $((10 + p)) set ports "0t 6t"
#   swconfig dev rtl8367rb vlan $((20 + p)) set ports "0t 7t"
# done

swconfig dev rtl8367rb set apply

ip link add link eth0 name wan type vlan id 1
ip link add link eth0 name lan type vlan id 2

ip link set dev eth0 up

