#!/bin/bash

set -euo pipefail

apt_install() {
  sudo apt-get -y update && \
  sudo apt-get -y install "$@"
}

install_corretto() {
  wget -qO - https://apt.corretto.aws/corretto.key \
    | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" \
    | sudo tee /etc/apt/sources.list.d/corretto.list > /dev/null && \
  aptInstall "java-11-amazon-corretto-jdk"
}

create_service_account() {
  local user="$1" group="$2"
  if ! getent group "$group" > /dev/null; then
    sudo groupadd -r "$group"
  fi

  if ! id "$user" >/dev/null 2>&1; then
    sudo useradd --system --no-create-home \
      --home-dir / --shell /usr/sbin/nologin \
      -g "$group" "$user"
  fi
}

download_file() {
  local url="$1" file="$2" folder="$3"
  if [ ! -e "${folder}/${file}" ]; then
    wget -q --show-progress -P "$folder" "$url/$file"
  fi
}

gpg_verify() {
  local folder="$1" file="$2" checksum_file="$3" algo="$4"
  cd $folder
  if gpg --print-md "$algo" "$file" | diff -q - "$checksum_file" > /dev/null; then
    echo "Checksum matches."
  else
    echo "Checksum mismatch."
    exit 1
  fi
}

create_random_password() {
  local pw_len="$1"
  LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c "${pw_len}"
  echo
}

check_file_exists() {
  local file="$1" error_msg="$2"
  if [[ ! -f "$file" ]]; then
    echo "$error_msg" >&2
    exit 1
  fi
}

append_to_file() {
  local file="$1" content="$2"
  echo "$content" | sudo tee -a "$file" > /dev/null
}

get_disk_name() {
  local index="$1"
  local dev_prefix="/dev/sd"
  printf "%s%s" "$dev_prefix" $(printf "\\$(printf '%03o' $((98 + $index)))")
}

start_service() {
  #local service="$1"
  sudo systemctl enable "$@" && \
  sudo systemctl start "$@"
}

restart_service() {
  #local service="$1"
  sudo systemctl restart "$@"
}

# add path for all users
update_profile_env() {
  local content="$1" script="$2"
  local profile="/etc/profile.d"

  echo "$content" | sudo tee "${profile}/${script}" > /dev/null
  sudo chmod 644 "${profile}/${script}"
}
