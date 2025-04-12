#!/bin/bash
set -e

# -----------------------------------------
# Remote Proxmox Lab Deployment Script
# -----------------------------------------

read -p "🔧 Enter the IP address of your Proxmox server: " PROXMOX_HOST
PROXMOX_USER="root"
REMOTE_DIR="/root/iac-lab"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"

# === Ensure 'expect' is installed (silent install) ===
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

# === Ensure SSH key exists ===
if [ ! -f ~/.ssh/id_rsa.pub ]; then
  ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa <<< y >/dev/null 2>&1
fi

# === Test SSH connectivity ===
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_TARGET" "echo ok" >/dev/null 2>&1; then
  echo "🔐 SSH key not found on remote host. Uploading it..."
  ssh-copy-id "$SSH_TARGET"
fi

# === Run deployment ===
ssh "$SSH_TARGET" "mkdir -p $REMOTE_DIR"

scp ./proxmox_templates/create_vm.sh "$SSH_TARGET:$REMOTE_DIR/create_vm.sh"
scp ./proxmox_templates/bootstrap/bootstrap_pfsense.expect "$SSH_TARGET:$REMOTE_DIR/bootstrap_pfsense.expect"

ssh "$SSH_TARGET" "cd $REMOTE_DIR && ./create_vm.sh"

expect ./proxmox_templates/bootstrap/bootstrap_pfsense.expect

bash ./ansible/inventories/generate_inventory.sh
