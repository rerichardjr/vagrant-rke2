# RKE2 Vagrant Cluster Setup

This repository contains a **Vagrantfile** that automates the provisioning of a lightweight **RKE2 (Rancher Kubernetes Engine 2)** cluster using VirtualBox. The setup is configurable via a `settings.yaml` file and includes optional add-ons like **Helm**, **Rancher**, **Cert Manager**, and **Longhorn**.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation Guide](#installation-guide)
  - [Installing VirtualBox](#installing-virtualbox)
  - [Installing Vagrant](#installing-vagrant)
- [Configuration](#configuration)
- [Usage](#usage)
- [Folder Structure](#folder-structure)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features
- Automated deployment of an RKE2 cluster using Vagrant and VirtualBox.
- Configurable settings via `settings.yaml`.
- Optional installation of add-ons: Helm, Rancher, Cert Manager, Longhorn.
- Custom bash scripts for further node configuration, located in the `scripts` folder.

## Prerequisites
Ensure you have the following installed:
- VirtualBox
- Vagrant
- Git

## Installation Guide

### Installing VirtualBox

#### **Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y virtualbox
```

#### **Fedora/RHEL:**
```bash
sudo dnf install -y @virtualization
sudo systemctl start vboxdrv
sudo systemctl enable vboxdrv
```

#### **macOS (with Homebrew):**
```bash
brew install --cask virtualbox
```

#### **Windows:**
1. Download the installer from [VirtualBox Downloads](https://www.virtualbox.org/wiki/Downloads).
2. Run the installer and follow the on-screen instructions.

### Installing Vagrant

#### **Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y vagrant
```

#### **Fedora/RHEL:**
```bash
sudo dnf install -y vagrant
```

#### **macOS (with Homebrew):**
```bash
brew install --cask vagrant
```

#### **Windows:**
1. Download the installer from [Vagrant Downloads](https://www.vagrantup.com/downloads).
2. Run the installer and follow the on-screen instructions.

## Configuration
All configuration options are managed through the `settings.yaml` file.

### Example `settings.yaml`:
```yaml
install_addons: true
```
- **install_addons:** Set to `true` to install Helm, Rancher, Cert Manager, and Longhorn automatically. Set to `false` to skip add-on installation.

### Add-ons
The list of addons include:
- **Helm:** Package manager for Kubernetes.
- **Rancher:** Kubernetes management platform.
- **Cert Manager:** Automates management and issuance of TLS certificates.
- **Longhorn:** Distributed block storage system for Kubernetes.


## Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/rerichardjr/vagrant-rke2.git
   cd vagrant-rke2
   ```
2. Modify `settings.yaml` as needed.
3. Start the cluster:
   ```bash
   vagrant up
   ```
4. To SSH into a VM:
   ```bash
   vagrant ssh <vm_name>
   ```
5. To halt the cluster:
   ```bash
   vagrant halt
   ```
6. To destroy the cluster:
   ```bash
   vagrant destroy -f
   ```

## Folder Structure
```
.
├── Vagrantfile
├── settings.yaml
├── scripts/
│   ├── addons.sh
│   ├── agent-node.sh
│   ├── common.sh
│   └── server-node.sh
└── README.md
```

## Troubleshooting
- **VM Startup Issues:**
  - Ensure virtualization is enabled in BIOS/UEFI.
  - Verify VirtualBox and Vagrant versions are compatible.

- **Network Configuration Errors:**
  - Check `scripts/configure_network.sh` for custom network settings.

- **Add-on Installation Fails:**
  - Review logs inside the VM (`/var/log` or specified log files).
  - Ensure internet connectivity inside the VM.

## License
This project is licensed under the [MIT License](LICENSE).

