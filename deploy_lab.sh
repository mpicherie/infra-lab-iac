#!/bin/bash
set -e

# -----------------------------------------
# Remote Proxmox Lab Deployment Script
# -----------------------------------------
# Author: Maxence PICHERIE (GitHub: @mpicherie)
# Description: This script connects to a remote Proxmox host,
#              uploads the VM creation script, and triggers deployment.
# -----------------------------------------

# === Configuration ===
PROXMOX_HOST="192.168.0.252"
PROXMOX_USER="root"
REMOTE_DIR="/root/iac-lab"
LOCAL_SCRIPT="./remote/create_vm.sh"
SSH_TARGET="${PROXMOX_USER}@${PROXMOX_HOST}"

echo ""
echo "🌐 Proxmox IaC Lab Deployment"
echo "========================================"
echo " Target Host : $PROXMOX_HOST"
echo " Remote User : $PROXMOX_USER"
echo " Remote Path : $REMOTE_DIR"
echo "----------------------------------------"
echo ""

# Step 1: Create remote directory
echo "📁 Creating remote working directory..."
ssh "$SSH_TARGET" "mkdir -p $REMOTE_DIR"

# Step 2: Upload the VM creation script
echo "📤 Uploading VM creation script..."
scp "$LOCAL_SCRIPT" "$SSH_TARGET:$REMOTE_DIR/create_vm.sh"

# Step 3: Make the script executable
echo "🔧 Setting execute permissions..."
ssh "$SSH_TARGET" "chmod +x $REMOTE_DIR/create_vm.sh"

# Step 4: Run the script on the Proxmox host
echo "🚀 Running VM deployment script on Proxmox..."
ssh "$SSH_TARGET" "cd $REMOTE_DIR && ./create_vm.sh"

echo "⚙️  Bootstrapping pfSense via console..."

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

expect ./remote/scripts/bootstrap_pfsense.expect

bash ./ansible/inventories/generate_inventory.sh


# Done
echo ""
echo "✅ Lab deployment complete!"
echo "You can now access your VMs via the Proxmox web interface."
echo ""
