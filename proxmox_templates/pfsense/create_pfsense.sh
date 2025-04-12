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

   # Delete existing VM if it exists
  if qm status $VM_ID &> /dev/null; then
    echo "⚠️  VM ID $VM_ID already exists — deleting it..."
    qm stop $VM_ID &> /dev/null || true
    qm destroy $VM_ID --purge
    echo "🗑️  VM $VM_ID deleted"
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


