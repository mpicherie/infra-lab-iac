#!/bin/bash
set -e

# ---------------------------------------------------
# Global Proxmox VM Configuration (shared variables)
# ---------------------------------------------------
export STORAGE="local"
export STORAGE_LVM="local-lvm"
export ISO_DIR="/var/lib/vz/template/iso"
export BRIDGE_WAN="vmbr0"
export BRIDGE_LAN="vmbr1"

# Load pfSense WAN IP (set by deploy_lab.sh)
export PFSENSE_WAN_IP=$(cat ./proxmox_templates/bootstrap/pfsense_wan_ip.txt)

# ---------------------------------------------------
# Run all VM creation scripts (modular)
# ---------------------------------------------------

./proxmox_templates/pfsense/create_pfsense.sh
./proxmox_templates/dns_dhcp/create_dns_dhcp.sh
./proxmox_templates/vpn/create_vpn.sh
./proxmox_templates/bastion/create_bastion.sh
./proxmox_templates/ansible/create_ansible.sh