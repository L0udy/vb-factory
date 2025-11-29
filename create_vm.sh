#!/bin/bash

CONFIG_FILE="$HOME/.vmfactory.conf"

### ============================================================
### FIRST-RUN SETUP WIZARD
### ============================================================

run_initial_setup() {
    echo "=============================================="
    echo "  VirtualBox VM Factory – Initial Setup"
    echo "=============================================="
    echo ""

    # Ask for VM base folder
    read -p "Enter base path for ALL VirtualBox VMs: " VM_BASE
    while [[ ! -d "$VM_BASE" ]]; do
        echo "Path does not exist. Please enter a valid folder."
        read -p "Enter base path for ALL VirtualBox VMs: " VM_BASE
    done

    # Ask for ISO folder
    read -p "Enter directory containing your ISO files: " ISO_DIR
    while [[ ! -d "$ISO_DIR" ]]; do
        echo "Path does not exist. Please enter a valid folder."
        read -p "Enter directory containing your ISO files: " ISO_DIR
    done

    # Ask for default NIC
    echo ""
    echo "Detecting available network interfaces:"
    ip -o link show | awk -F': ' '{print " - " $2}'
    echo ""

    read -p "Enter default NIC for bridged networking: " DEFAULT_NIC

    echo ""
    echo "Saving configuration..."
    cat <<EOF > "$CONFIG_FILE"
VM_BASE="$VM_BASE"
ISO_DIR="$ISO_DIR"
DEFAULT_NIC="$DEFAULT_NIC"
DEFAULT_VM_NAME="myvm"
DEFAULT_OS_TYPE="Ubuntu_64"
DEFAULT_RAM_SIZE=1024
DEFAULT_VRAM_SIZE=16
DEFAULT_CPU_CORES=1
DEFAULT_DISK_SIZE=10000
EOF

    echo "Configuration saved to $CONFIG_FILE"
    echo "Setup complete!"
    echo ""
}

### ============================================================
### RESET CONFIG IF NEEDED
### ============================================================

if [[ "$1" == "--reset" ]]; then
    echo "Resetting VM factory configuration..."
    rm -f "$CONFIG_FILE"
    run_initial_setup
    exit 0
fi

### ============================================================
### LOAD CONFIG OR RUN FIRST SETUP
### ============================================================

if [[ ! -f "$CONFIG_FILE" ]]; then
    run_initial_setup
fi

# Load saved config
source "$CONFIG_FILE"

### ============================================================
### VERIFY PATHS EXIST – IF NOT, RECONFIGURE
### ============================================================

if [[ ! -d "$VM_BASE" || ! -d "$ISO_DIR" ]]; then
    echo "!! WARNING: One or more configured paths no longer exist."
    echo "Re-running setup wizard..."
    run_initial_setup
    source "$CONFIG_FILE"
fi

### ============================================================
### SYSTEM INFORMATION
### ============================================================

echo "=============================="
echo "   Your System Information"
echo "=============================="
echo ""
echo "CPU Cores:     $(nproc)"
echo "Total RAM:     $(free -h | awk '/Mem:/ {print $2}')"
echo "Free RAM:      $(free -h | awk '/Mem:/ {print $7}')"
echo ""
echo "VM Storage:    $VM_BASE"
echo "ISO Storage:   $ISO_DIR"
echo ""
echo "Disk Space:"
df -h "$VM_BASE"
echo ""
echo "=============================="
echo ""

### ============================================================
### USER INPUT WITH DEFAULTS
### ============================================================

echo "====== VM Creation (Safe Defaults Enabled) ======"
echo "Press ENTER to use the default value."
echo ""

read -p "VM Name (default: $DEFAULT_VM_NAME): " VM_NAME
VM_NAME=${VM_NAME:-$DEFAULT_VM_NAME}

# Sanitize VM name (letters, numbers, dot, dash, underscore only)
VM_NAME=$(echo "$VM_NAME" | sed 's/[^A-Za-z0-9._-]/_/g')
# Prevent names starting with invalid characters: replace leading non-alphanumerics
VM_NAME=$(echo "$VM_NAME" | sed 's/^[^A-Za-z0-9]//')

read -p "OS Type (default: $DEFAULT_OS_TYPE): " OS_TYPE
OS_TYPE=${OS_TYPE:-$DEFAULT_OS_TYPE}

read -p "Memory MB (default: $DEFAULT_RAM_SIZE): " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-$DEFAULT_RAM_SIZE}

read -p "Video RAM MB (default: $DEFAULT_VRAM_SIZE): " VRAM_SIZE
VRAM_SIZE=${VRAM_SIZE:-$DEFAULT_VRAM_SIZE}

read -p "CPU cores (default: $DEFAULT_CPU_CORES): " CPU_CORES
CPU_CORES=${CPU_CORES:-$DEFAULT_CPU_CORES}

read -p "Disk Size MB (default: $DEFAULT_DISK_SIZE = 10GB): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-$DEFAULT_DISK_SIZE}

### ============================================================
### ISO SELECTION MENU
### ============================================================

echo ""
echo "Available ISOs in $ISO_DIR:"
ISO_LIST=("$ISO_DIR"/*.iso)
COUNTER=1

for iso in "${ISO_LIST[@]}"; do
    if [[ -f "$iso" ]]; then
        echo "  $COUNTER) $(basename "$iso")"
        ((COUNTER++))
    fi
done

CUSTOM_OPTION=$COUNTER
NO_ISO_OPTION=$((COUNTER + 1))

echo "  $CUSTOM_OPTION) Provide custom ISO path"
echo "  $NO_ISO_OPTION) Leave empty (no ISO)"
echo "-----------------------------------------------------------"

read -p "Choose ISO number: " ISO_CHOICE

if [[ "$ISO_CHOICE" -ge 1 && "$ISO_CHOICE" -lt "$COUNTER" ]]; then
    ISO_PATH="${ISO_LIST[$((ISO_CHOICE-1))]}"
elif [[ "$ISO_CHOICE" -eq "$CUSTOM_OPTION" ]]; then
    read -p "Enter custom ISO path: " ISO_PATH
    if [[ ! -f "$ISO_PATH" ]]; then
        echo "!! ERROR: Provided ISO path does not exist!"
        exit 1
    fi
elif [[ "$ISO_CHOICE" -eq "$NO_ISO_OPTION" ]]; then
    ISO_PATH=""
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo "Selected ISO: ${ISO_PATH:-<none>}"
echo ""

### ============================================================
### CREATE VM DIRECTORY
### ============================================================

VM_DIR="$VM_BASE/$VM_NAME"
mkdir -p "$VM_DIR"

### ============================================================
### CREATE VM
### ============================================================

echo "[+] Creating VM '$VM_NAME'..."
VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --register \
    --basefolder "$VM_BASE"

### ============================================================
### HARDWARE CONFIGURATION
### ============================================================

VBoxManage modifyvm "$VM_NAME" \
    --memory "$RAM_SIZE" \
    --vram "$VRAM_SIZE" \
    --cpus "$CPU_CORES" \
    --graphicscontroller vmsvga \
    --nic1 bridged \
    --bridgeadapter1 "$DEFAULT_NIC"

### ============================================================
### VIRTUAL DISK
### ============================================================

echo "[+] Creating virtual disk..."
VBoxManage createmedium disk \
    --filename "$VM_DIR/$VM_NAME.vdi" \
    --size "$DISK_SIZE"

### ============================================================
### STORAGE CONTROLLERS
### ============================================================

VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci

VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA" --port 0 --device 0 \
    --type hdd --medium "$VM_DIR/$VM_NAME.vdi"

if [[ -n "$ISO_PATH" ]]; then
    VBoxManage storageattach "$VM_NAME" \
        --storagectl "SATA" --port 1 --device 0 \
        --type dvddrive --medium "$ISO_PATH"
fi

### ============================================================
### DONE
### ============================================================

echo ""
echo "=============================================="
echo " VM '$VM_NAME' successfully created!"
echo " Folder: $VM_DIR"
echo ""
echo " To start the VM:"
echo "   VBoxManage startvm \"$VM_NAME\" --type gui"
echo "=============================================="
