#!/bin/bash
set -e

# ---------------------------------------------------
# Create Ansible + Bastion VM with cloud-init
# ---------------------------------------------------

VM_ID=110
VM_NAME="vm-ansible"
IMAGE_URL="https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-amd64.img"
IMAGE_FILE="oracular-server-cloudimg-amd64.img"
STORAGE="local-lvm"
CLOUDINIT_STORAGE="local"
USERDATA_SRC="./proxmox_templates/ansible/user-data.yml"
USERDATA_DEST="/var/lib/vz/snippets/user-data.yml"
BRIDGE_WAN="vmbr0"

# ---------------------------------------------------
# Download image if not present
# ---------------------------------------------------
if [ ! -f "$IMAGE_FILE" ]; then
  echo "📥 Downloading Ubuntu Cloud-Init image..."
  wget "$IMAGE_URL" -O "$IMAGE_FILE"
fi

# ---------------------------------------------------
# Copy cloud-init user-data
# ---------------------------------------------------
if [ ! -f "$USERDATA_SRC" ]; then
  echo "❌ user-data.yml not found at $USERDATA_SRC"
  exit 1
fi

echo "📦 Copying user-data to Proxmox snippets..."
cp "$USERDATA_SRC" "$USERDATA_DEST"

# ---------------------------------------------------
# Delete existing VM
# ---------------------------------------------------
if qm status $VM_ID &> /dev/null; then
  echo "⚠️  VM ID $VM_ID already exists — deleting it..."
  qm stop $VM_ID &> /dev/null || true
  qm destroy $VM_ID --purge
fi

# ---------------------------------------------------
# Create the VM
# ---------------------------------------------------
qm create $VM_ID \
  --name $VM_NAME \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$BRIDGE_WAN \
  --serial0 socket \
  --vga serial0 \
  --scsihw virtio-scsi-pci \
  --ostype l26

# ---------------------------------------------------
# Import and attach disk
# ---------------------------------------------------
qm importdisk $VM_ID $IMAGE_FILE $STORAGE
qm set $VM_ID --scsi0 ${STORAGE}:vm-${VM_ID}-disk-0
qm set $VM_ID --boot order=scsi0

# ---------------------------------------------------
# Attach cloud-init + inject config
# ---------------------------------------------------
qm set $VM_ID \
  --ide2 ${CLOUDINIT_STORAGE}:cloudinit \
  --ciuser ansible \
  --cipassword ansible123 \
  --sshkeys "$(cat ~/.ssh/id_rsa.pub)" \
  --cicustom "user=${CLOUDINIT_STORAGE}:snippets/user-data.yml"

# ---------------------------------------------------
# Start VM
# ---------------------------------------------------
qm start $VM_ID
echo "✅ Ansible Control VM created and started (ID $VM_ID)"

# ---------------------------------------------------
# Ask for VM IP (manual for now)
# ---------------------------------------------------
read -p "🌐 Enter the IP address of the vm-ansible (WAN): " ANSIBLE_IP

# ---------------------------------------------------
# Send ansible project files to the VM
# ---------------------------------------------------
echo "📤 Sending Ansible files to vm-ansible (${ANSIBLE_IP})..."

scp -r ansible/* ansible@${ANSIBLE_IP}:/home/ansible/ansible/

ssh ansible@${ANSIBLE_IP} <<EOF
sudo chown -R ansible:ansible /home/ansible/ansible
echo "✅ Ansible files received and ready."
EOF
