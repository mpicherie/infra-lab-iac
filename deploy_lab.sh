#!/bin/bash
set -e

# -----------------------------------------
# Local Proxmox Lab Deployment Script
# -----------------------------------------


# Make sure all necessary scripts are executable
chmod +x ./proxmox_templates/*.sh
chmod +x ./proxmox_templates/pfsense/*.sh
chmod +x ./proxmox_templates/vpn/*.sh
chmod +x ./proxmox_templates/dns_dhcp/*.sh
chmod +x ./proxmox_templates/ansible/*.sh



# --------------------------------------------------------
# Ensure 'expect' and 'sshpass' are installed (silent install)
# --------------------------------------------------------

if ! command -v expect &> /dev/null || ! command -v sshpass &> /dev/null; then
  echo "📦 Installing 'expect' and 'sshpass'..."

  if [ -f /etc/debian_version ]; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq expect sshpass >/dev/null 2>&1
  elif [ -f /etc/redhat-release ]; then
    yum install -y expect sshpass >/dev/null 2>&1
  else
    echo "❌ Unsupported OS. Install 'expect' and 'sshpass' manually."
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
echo ""
echo "🎉 All VMs have been created successfully!"

echo ""
echo "⚠️  Manual installation required for pfSense (vm-pfsense):"
echo "   1. Open the Proxmox Web UI"
echo "   2. Select the VM 'vm-pfsense' (ID 100)"
echo "   3. Open the Console"
echo "   4. Complete the pfSense installation using the ISO installer"
echo ""
echo "💡 Once pfSense is installed and running:"
echo "   - Enable SSH: System > Advanced > Admin Access"
echo "   - Install the pfSense API package:"
echo "       pkg install -y pfSense-pkg-API"
echo "   - Create an API user (e.g., 'ansible')"
echo ""
echo "🚀 After that, you can run Ansible to configure pfSense automatically!"


