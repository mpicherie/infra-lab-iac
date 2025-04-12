#!/bin/bash
set -e

# -----------------------------------------
# Remote Proxmox Lab Deployment Script
# -----------------------------------------

PROXMOX_HOST="192.168.1.10"   # À modifier selon ton setup
PROXMOX_USER="root"
REMOTE_DIR="/root/iac-lab"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"

# Step 0 - Ensure expect is installed (silent)
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

# Step 1 - Create working directory on remote Proxmox
ssh "$SSH_TARGET" "mkdir -p $REMOTE_DIR"

# Step 2 - Upload VM creation script
scp ./proxmox_templates/create_vm.sh "$SSH_TARGET:$REMOTE_DIR/create_vm.sh"

# Step 3 - Upload pfSense bootstrap script
scp ./proxmox_templates/bootstrap/bootstrap_pfsense.expect "$SSH_TARGET:$REMOTE_DIR/bootstrap_pfsense.expect"

# Step 4 - Set execute permissions
ssh "$SSH_TARGET" "chmod +x $REMOTE_DIR/create_vm.sh $REMOTE_DIR/bootstrap_pfsense.expect"

# Step 5 - Execute VM creation remotely
ssh "$SSH_TARGET" "cd $REMOTE_DIR && ./create_vm.sh"

# Step 6 - Bootstrap pfSense API (from your machine)
expect ./proxmox_templates/bootstrap/bootstrap_pfsense.expect

# Step 7 - Generate dynamic inventory
bash ./ansible/inventories/generate_inventory.sh
