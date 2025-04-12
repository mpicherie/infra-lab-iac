#!/bin/bash

# Paths
INVENTORY_PATH="./ansible/inventories/hosts.ini"
PFSENSE_WAN_IP_FILE="/tmp/pfsense_wan_ip.txt"

# Read dynamic IPs
PFSENSE_WAN_IP=$(cat "$PFSENSE_WAN_IP_FILE")
LAN_PREFIX="192.168.100"
WAN_PREFIX="192.168.0"

# Generate hosts.ini
cat > "$INVENTORY_PATH" <<EOF
[pfsense]
$PFSENSE_WAN_IP ansible_user=ansible ansible_password=ansible123 ansible_connection=local

[vpn]
$LAN_PREFIX.10 ansible_user=ubuntu ansible_password=ubuntu ansible_connection=ssh

[dns_dhcp]
$LAN_PREFIX.20 ansible_user=ubuntu ansible_password=ubuntu ansible_connection=ssh

[bastion]
$WAN_PREFIX.60 ansible_user=ubuntu ansible_password=ubuntu ansible_connection=ssh

[ansible_control]
$WAN_PREFIX.70 ansible_user=ubuntu ansible_password=ubuntu ansible_connection=ssh
EOF
