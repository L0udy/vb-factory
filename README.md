# VirtualBox VM Factory
A self-configuring automation script for creating VirtualBox virtual machines with safe defaults, ISO selection, and persistent settings. Designed for home lab environments, training setups, and rapid VM deployment.

---

## ✨ Features

### 🔧 One-Time Setup Wizard
The script detects when it is run for the first time and asks you to configure:
- VM storage directory (e.g. external disk)
- ISO directory
- Default bridged network interface  
- All settings saved permanently in `~/.vmfactory.conf`

No repeated prompts. Re-run setup anytime with:
./create_vm.sh --reset


## 🚀 VM Creation Made Simple

Each run prompts for:
- VM name (with automatic sanitization)
- OS type
- RAM, CPU, VRAM
- Disk size
- ISO selection from menu  
- Or option to provide custom ISO  
- Or create a VM without ISO

It automatically:
- Creates the VM directory inside your chosen location  
- Creates the disk  
- Configures CPU + RAM  
- Attaches ISO  
- Registers the VM with VirtualBox  

At the end, you get a clean summary and a command to launch the VM.

---

## 🔒 Safe Defaults

Optimized for home labs:
- 1 vCPU  
- 1 GB RAM  
- 16 MB VRAM  
- 10 GB disk  
- Ubuntu_64 OS type (modifiable)  

Defaults are chosen to avoid overloading your machine while allowing many small VMs to run simultaneously.

---

## 🧹 VM Name Sanitization

Prevents unexpected characters such as:
- `#`
- spaces
- unicode / control characters  
- leading non-alphanumeric characters  

Sanitized names avoid VirtualBox folder inconsistencies like:
#vmname
_vmname

## 📂 Persistent Configuration

All paths and settings are stored in:
~/.vmfactory.conf

You can edit this file manually or regenerate via:
./create_vm.sh --reset

## 📦 Example Usage

./create_vm.sh

css
Copy code

You will see system info, ISO menu, and creation progress similar to:

[+] Creating VM 'myvm'...
UUID: 943e5f06-dde4-4889-bb31-1f2e78d483e9
Settings file: '/run/media/.../myvm/myvm.vbox'
Medium created. UUID: 406958b5-7e3c...

---

## 🏗 Designed For Home Labs

This script is ideal for:
- Creating many small purpose VMs  
- Small test VMs  
- Learning infrastructure automation

---

## 👤 Author
L0udy
Automated VM Factory Script  
Created for home lab infrastructure automation.
