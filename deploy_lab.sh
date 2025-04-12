#!/bin/bash
set -e

# -----------------------------------------
# Remote Proxmox Lab Deployment Script
# -----------------------------------------

# Ask for Proxmox host IP
read -p "🔧 Enter the IP address of your Proxmox server: " PROXMOX_HOST
PROXMOX_USER="root"
REMOTE_DIR="/root/iac-lab"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"

# Ensure 'expect' is installed (silent mode)
if ! command -v expect &> /dev/null; then
  if [ "$(uname)" = "Linux" ]; then
    if [ -f /etc/debian_version ]; then
      sudo apt-get update -qq >/dev/null 2>&1
      sudo apt-get install -y -qq expect >/dev/null 2>&1
    elif [ -f /etc/redhat-release ]; then
      sudo yum install -y expect >/dev/null 2>&1
    else
      exit 1
    fi
  elif [ "$(uname)" = "Darwin" ]; then
    exit 1
  else
    exit 1
  fi
fi

# Create working directory on the remote Proxmox host
ssh "$SSH_TARGET" "mkdir -p $REMOTE_DIR"

# Upload VM creation script
scp ./proxmox_templates/create_vm.sh "$SSH_TARGET:$REMOTE_DIR/create_vm.sh"

# Upload pfSense bootstrap script
scp ./proxmox_templates/bootstrap/bootstrap_pfsense.expect "$SSH_TARGET:$REMOTE_DIR/bootstrap_pfsense.expect"

# Set execute permissions
ssh "$SSH_TARGET" "chmod +x $REMOTE_DIR/create_vm.sh $REMOTE_DIR/bootstrap_pfsense.expect"

# Execute VM creation script on Proxmox
ssh "$SSH_TARGET" "cd $REMOTE_DIR && ./create_vm.sh"

# Execute pfSense bootstrap from local machine (talks to Proxmox VM)
expect ./proxmox_templates/bootstrap/bootstrap_pfsense.expect

# Generate the dynamic inventory file
bash ./ansible/inventories/generate_inventory.sh
