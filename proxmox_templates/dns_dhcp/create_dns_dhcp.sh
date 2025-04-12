#!/bin/bash
set -e

# ---------------------------------------------------
# DNS/DHCP VM Creation Script
# ---------------------------------------------------

VM_ID=102
VM_NAME="vm-dns-dhcp"
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
# Create the DNS/DHCP VM
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
echo "✅ DNS/DHCP VM created and started (ID $VM_ID)"
