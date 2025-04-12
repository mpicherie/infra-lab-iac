#!/bin/bash
set -e

# ---------------------------------------------------
# Bastion VM Creation Script (SSH + UFW)
# ---------------------------------------------------

VM_ID=103
VM_NAME="vm-bastion"
ISO_URL="https://repo.ialab.dsu.edu/ubuntu-releases/24.10/ubuntu-24.10-live-server-amd64.iso"
ISO_NAME="ubuntu-24.10-live-server-amd64.iso"
ISO_PATH="$ISO_DIR/$ISO_NAME"

# ---------------------------------------------------
# Download the ISO if it doesn't exist
# ---------------------------------------------------
if [ ! -f "$ISO_PATH" ]; then
  echo "📥 Downloading Ubuntu 24.10 ISO..."
  wget -O "$ISO_PATH" "$ISO_URL"
fi

# ---------------------------------------------------
# Delete existing VM if it exists
# ---------------------------------------------------
if qm status $VM_ID &> /dev/null; then
  echo "⚠️  VM ID $VM_ID already exists — deleting it..."
  qm stop $VM_ID &> /dev/null || true
  qm destroy $VM_ID --purge
  echo "🗑️  VM $VM_ID deleted"
fi

# ---------------------------------------------------
# Create the Bastion VM
# ---------------------------------------------------
qm create $VM_ID \
  --name $VM_NAME \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$BRIDGE_WAN \
  --net1 virtio,bridge=$BRIDGE_LAN \
  --ide2 $STORAGE:iso/$ISO_NAME,media=cdrom \
  --boot order=ide2 \
  --ostype l26 \
  --scsihw virtio-scsi-pci \
  --virtio0 $STORAGE_LVM:8 \
  --serial0 socket --vga serial0

# ---------------------------------------------------
# Start the VM
# ---------------------------------------------------
qm start $VM_ID
echo "✅ Bastion VM created and started (ID $VM_ID)"

# ---------------------------------------------------
# Setup UFW (Uncomplicated Firewall) and SSH
# ---------------------------------------------------

# Wait for VM to finish booting (you can adjust this sleep time)
sleep 30

# Enable UFW and allow SSH only
echo "🔧 Configuring UFW on Bastion VM..."
sshpass -p 'your-password' ssh -o StrictHostKeyChecking=no -t root@$(hostname -I | awk '{print $1}') \
  "ufw default deny incoming && ufw default allow outgoing && ufw allow ssh && ufw enable"

echo "✅ Bastion VM setup complete with SSH access secured using UFW."
