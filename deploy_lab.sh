#!/bin/bash
set -e

# -----------------------------------------
# Local Proxmox Lab Deployment Script
# -----------------------------------------

# Ask the user for pfSense WAN IP
read -p "🌐 Enter the static WAN IP for pfSense (e.g. 192.168.0.50): " PFSENSE_WAN_IP
echo "$PFSENSE_WAN_IP" > ./proxmox_templates/bootstrap/pfsense_wan_ip.txt

# Make sure all necessary scripts are executable
chmod +x ./proxmox_templates/create_vm.sh
chmod +x ./proxmox_templates/bootstrap/bootstrap_pfsense.expect
chmod +x ./ansible/inventories/generate_inventory.sh

# === Run all steps locally ===

# 1. Create all VMs
./proxmox_templates/create_vm.sh

# 2. Bootstrap pfSense (set static IP, enable API, create user)
./proxmox_templates/bootstrap/bootstrap_pfsense.expect

# 3. Generate Ansible inventory
./ansible/inventories/generate_inventory.sh

echo ""
echo "✅ Lab deployment complete!"
echo "You can now run:"
echo "ansible-playbook -i ansible/inventories/hosts.ini ansible/playbooks/test_pfsense_api.yml"
