#!/bin/bash
set -e

# -----------------------------------------
# Local Proxmox Lab Deployment Script
# -----------------------------------------

# Ask the user for pfSense WAN IP
read -p "🌐 Enter the static WAN IP for pfSense (e.g. 192.168.0.50): " PFSENSE_WAN_IP
echo "$PFSENSE_WAN_IP" > ./proxmox_templates/bootstrap/pfsense_wan_ip.txt

# Make sure all necessary scripts are executable
chmod +x ./proxmox_templates/*.sh
chmod +x ./proxmox_templates/pfSense/*.sh
chmod +x ./proxmox_templates/vpn/*.sh
chmod +x ./proxmox_templates/dns_dhcp/*.sh
chmod +x ./proxmox_templates/bastion/*.sh
chmod +x ./proxmox_templates/ansible/*.sh


if ! command -v expect &> /dev/null; then
  echo "📦 Installing 'expect'..."
  if [ -f /etc/debian_version ]; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq expect >/dev/null 2>&1
  elif [ -f /etc/redhat-release ]; then
    yum install -y expect >/dev/null 2>&1
  else
    echo "❌ Unsupported OS. Install 'expect' manually."
    exit 1
  fi
fi

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
