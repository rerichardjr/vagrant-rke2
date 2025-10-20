#!/bin/bash

set -euxo pipefail

fix_routing() {
  local netplan_config="/etc/netplan/01-netcfg.yaml"
  
  sudo chmod 600 /etc/netplan/*.yaml
  sudo chown root:root /etc/netplan/*.yaml

  if [ -f "$netplan_config" ]; then
    cat > "$netplan_config" <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes
      dhcp4-overrides:
        route-metric: 200
    eth1:
      routes:
        - to: 0.0.0.0/0
          via: ${NETWORK}.1
      nameservers:
        addresses:
          - 208.67.222.222
          - 208.67.220.220
EOF
  fi

  sudo netplan apply

}

update_hosts_file() {
  local hosts_file="/etc/hosts"
  local regex_ip="^127\.0\.[0-9]+\.[0-9]+"

  echo "$HOSTNAME_IP_MAP" | jq -r 'to_entries[] | "\(.key) \(.value)"' |
  while read -r host ip; do
    # Remove any existing matching line for this host/IP
    sudo sed -i "\|${ip} ${host}.${DOMAIN} ${host}|d" "$hosts_file"

    echo "$ip ${host}.${DOMAIN} ${host}" | sudo tee -a "$hosts_file" > /dev/null
    
    sudo sed -i -E "s/^${regex_ip} ${host} ${host}/#&/" "$hosts_file"
  done
}

fix_routing
update_hosts_file
