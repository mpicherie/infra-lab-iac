#!/bin/bash
set -e

# Configuration globale
STORAGE="local"
STORAGE_LVM="local-lvm"
ISO_DIR="/var/lib/vz/template/iso"
BRIDGE_WAN="vmbr0"
BRIDGE_LAN="vmbr1"

# ---------- PF-SENSE ----------
create_pfsense_vm() {
  echo "🔧 Creating vm-pfsense..."

  VM_ID=100
  VM_NAME="vm-pfsense"

  ISO_URL="https://repo.ialab.dsu.edu/pfsense/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz"
  ISO_GZ_NAME="pfSense-CE-2.7.2-RELEASE-amd64.iso.gz"
  ISO_NAME="pfSense-CE-2.7.2-RELEASE-amd64.iso"
  ISO_PATH="$ISO_DIR/$ISO_NAME"
  ISO_GZ_PATH="$ISO_DIR/$ISO_GZ_NAME"

  # Ensure gunzip is available
  if ! command -v gunzip >/dev/null 2>&1; then
    echo "📦 Installing gzip..."
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq gzip >/dev/null 2>&1
  fi

  # Download and extract ISO if not already present
  if [ ! -f "$ISO_PATH" ]; then
    if [ ! -f "$ISO_GZ_PATH" ]; then
      echo "📥 Downloading pfSense ISO (.gz)..."
      wget -O "$ISO_GZ_PATH" "$ISO_URL"
    fi

    echo "📦 Extracting pfSense ISO..."
    gunzip -c "$ISO_GZ_PATH" > "$ISO_PATH"

    echo "🧹 Cleaning up .gz..."
    rm -f "$ISO_GZ_PATH"
  fi

  # Create the VM
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


  qm start $VM_ID
  echo "✅ pfSense VM created and started (ID $VM_ID)"
}



# ---------- VPN SERVER ----------
create_vpn_vm() {
  echo "🔧 Création de vm-vpn-server..."

  VM_ID=101
  VM_NAME="vm-vpn-server"
  IMG_NAME="ubuntu-22.04-server-cloudimg-amd64.img"
  IMG_URL="https://cloud-images.ubuntu.com/releases/22.04/release/$IMG_NAME"
  IMG_PATH="/var/lib/vz/template/qemu/$IMG_NAME"

  # Téléchargement de l'image si absente
  if [ ! -f "$IMG_PATH" ]; then
    echo "📥 Téléchargement de l’image Ubuntu Cloud-Init..."
    wget -O "$IMG_PATH" "$IMG_URL"
  fi

  # Création de la VM
  qm create $VM_ID \
    --name $VM_NAME \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=$BRIDGE_LAN \
    --serial0 socket --vga serial0 \
    --ciuser ubuntu \
    --cipassword ubuntu \
    --ide2 $STORAGE:cloudinit \
    --ipconfig0 ip=dhcp \
    --boot order=virtio0

  # Import du disque
  qm importdisk $VM_ID "$IMG_PATH" $STORAGE_LVM

  # Attache le disque importé
  qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 $STORAGE_LVM:vm-$VM_ID-disk-0

  echo "✅ VM vpn-server créée (ID $VM_ID)"
}

# ---------- DNS + DHCP SERVER ----------
create_dns_dhcp_vm() {
  echo "🔧 Création de vm-dns-dhcp..."

  VM_ID=102
  VM_NAME="vm-dns-dhcp"
  IMG_NAME="ubuntu-22.04-server-cloudimg-amd64.img"
  IMG_URL="https://cloud-images.ubuntu.com/releases/22.04/release/$IMG_NAME"
  IMG_PATH="/var/lib/vz/template/qemu/$IMG_NAME"

  # Téléchargement de l'image si absente
  if [ ! -f "$IMG_PATH" ]; then
    echo "📥 Téléchargement de l’image Ubuntu Cloud-Init..."
    wget -O "$IMG_PATH" "$IMG_URL"
  fi

  # Création de la VM
  qm create $VM_ID \
    --name $VM_NAME \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=$BRIDGE_LAN \
    --serial0 socket --vga serial0 \
    --ciuser ubuntu \
    --cipassword ubuntu \
    --ide2 $STORAGE:cloudinit \
    --ipconfig0 ip=dhcp \
    --boot order=virtio0

  # Import du disque
  qm importdisk $VM_ID "$IMG_PATH" $STORAGE_LVM

  # Attache le disque importé
  qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 $STORAGE_LVM:vm-$VM_ID-disk-0

  echo "✅ VM dns-dhcp créée (ID $VM_ID)"
}

# ---------- ANSIBLE CONTROL NODE ----------
create_ansible_vm() {
  echo "🔧 Création de vm-ansible..."

  VM_ID=104
  VM_NAME="vm-ansible"
  IMG_NAME="ubuntu-22.04-server-cloudimg-amd64.img"
  IMG_URL="https://cloud-images.ubuntu.com/releases/22.04/release/$IMG_NAME"
  IMG_PATH="/var/lib/vz/template/qemu/$IMG_NAME"

  # Téléchargement de l'image si absente
  if [ ! -f "$IMG_PATH" ]; then
    echo "📥 Téléchargement de l’image Ubuntu Cloud-Init..."
    wget -O "$IMG_PATH" "$IMG_URL"
  fi

  # Création de la VM
  qm create $VM_ID \
    --name $VM_NAME \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=$BRIDGE_WAN \
    --serial0 socket --vga serial0 \
    --ciuser ubuntu \
    --cipassword ubuntu \
    --ide2 $STORAGE:cloudinit \
    --ipconfig0 ip=dhcp \
    --boot order=virtio0

  # Import du disque
  qm importdisk $VM_ID "$IMG_PATH" $STORAGE_LVM

  # Attache le disque importé
  qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 $STORAGE_LVM:vm-$VM_ID-disk-0

  echo "✅ VM ansible créée (ID $VM_ID)"
}

# ---------- BASTION / JUMPBOX ----------
create_bastion_vm() {
  echo "🔧 Création de vm-bastion..."

  VM_ID=103
  VM_NAME="vm-bastion"
  IMG_NAME="ubuntu-22.04-server-cloudimg-amd64.img"
  IMG_URL="https://cloud-images.ubuntu.com/releases/22.04/release/$IMG_NAME"
  IMG_PATH="/var/lib/vz/template/qemu/$IMG_NAME"

  # Téléchargement de l'image si absente
  if [ ! -f "$IMG_PATH" ]; then
    echo "📥 Téléchargement de l’image Ubuntu Cloud-Init..."
    wget -O "$IMG_PATH" "$IMG_URL"
  fi

  # Création de la VM
  qm create $VM_ID \
    --name $VM_NAME \
    --memory 1024 \
    --cores 1 \
    --net0 virtio,bridge=$BRIDGE_WAN \
    --serial0 socket --vga serial0 \
    --ciuser ubuntu \
    --cipassword ubuntu \
    --ide2 $STORAGE:cloudinit \
    --ipconfig0 ip=dhcp \
    --boot order=virtio0

  # Import du disque
  qm importdisk $VM_ID "$IMG_PATH" $STORAGE_LVM

  # Attache le disque importé
  qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 $STORAGE_LVM:vm-$VM_ID-disk-0

  echo "✅ VM bastion créée (ID $VM_ID)"
}



# ---------- À venir : VPN, DNS, Bastion, etc ----------
# create_vpn_vm() {

create_pfsense_vm
create_vpn_vm
create_dns_dhcp_vm
create_bastion_vm
create_ansible_vm