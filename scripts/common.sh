#!/bin/bash

set -euxo pipefail

source "$(dirname "$0")/lib.sh"

KEY_DIR="/vagrant/keys"
PRIVATE_KEY="$KEY_DIR/id_${SUPPORT_USER}"
PUBLIC_KEY="$KEY_DIR/id_${SUPPORT_USER}.pub"

create_support_user() {
  local ssh_folder="/home/${SUPPORT_USER}/.ssh"
  local auth_keys="authorized_keys"

  # Create user if not exists, with no password
  if ! id "$SUPPORT_USER" >/dev/null 2>&1; then
    sudo useradd "$SUPPORT_USER" -G sudo -m -s /bin/bash
    sudo passwd -l "$SUPPORT_USER"  # lock password
    echo "User $SUPPORT_USER created (password login disabled)."
  else
    sudo passwd -l "$SUPPORT_USER"  # ensure password stays locked
  fi

  # Generate SSH key if not already present locally
  if [ ! -f "$PRIVATE_KEY" ]; then
    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR"
    ssh-keygen -q -t rsa -b 4096 -f "$PRIVATE_KEY" -N ""
    echo "SSH key pair generated at $KEY_DIR"
  fi

  # Set up .ssh for support user
  sudo mkdir -p "${ssh_folder}"
  sudo touch "${ssh_folder}/${auth_keys}"
  sudo chmod 700 "${ssh_folder}"
  sudo chmod 600 "${ssh_folder}/${auth_keys}"

  # Append public key if not already present
  if ! grep -q -F "$(cat "$PUBLIC_KEY")" "${ssh_folder}/${auth_keys}"; then
    cat "$PUBLIC_KEY" | sudo tee -a "${ssh_folder}/${auth_keys}" > /dev/null
    echo "Public key added to ${auth_keys}"
  fi

  sudo chown -R "${SUPPORT_USER}:${SUPPORT_USER}" "${ssh_folder}"
}

generate_putty_key() {
  # Convert to PuTTY .ppk format
  local ppk_file="$KEY_DIR/$(basename "$PRIVATE_KEY").ppk"

  # Ensure putty-tools is installed for PuTTY key conversion
  if ! command -v puttygen >/dev/null 2>&1; then
    echo "Installing putty-tools..."
    apt_install "putty-tools"
  fi

  if [ ! -f "$ppk_file" ]; then
    puttygen "$PRIVATE_KEY" -o "$ppk_file"
    chmod 600 "$ppk_file"
    echo "PuTTY key created at $ppk_file"
  fi
}

create_support_user
generate_putty_key
apt_install open-iscsi nfs-common
