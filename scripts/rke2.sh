#!/bin/bash
set -euxo pipefail

source "$(dirname "$0")/lib.sh"

CONFIG_DIR="/etc/rancher/rke2"
SERVER_DIR="/var/lib/rancher/rke2/server"
MANIFESTS_DIR="//var/lib/rancher/rke2/server/manifests"
BIN_DIR="/var/lib/rancher/rke2/bin"
FILES_DIR="/vagrant/files"

CONFIG_FILE="${CONFIG_DIR}/config.yaml"
NODE_TOKEN="${SERVER_DIR}/node-token"
NODE_TOKEN_FILE="${FILES_DIR}/node-token"
KUBEVIP_RBAC="${MANIFESTS_DIR}/kube-vip-rbac.yaml"
KUBEVIP_MANIFEST="${MANIFESTS_DIR}/kube-vip.yaml"
VIP_INTERFACE="eth1"

CURRENT_HOST="$(hostname -s)"
HOST_ROW="$(jq -c --arg h "$CURRENT_HOST" 'to_entries[] | select(.key == $h)' <<< "$HOSTNAME_IP_MAP")"
HOSTNAME="$(jq -r '.key' <<< "$HOST_ROW")"
HOST_IP="$(jq -r '.value' <<< "$HOST_ROW")"

mkdir -p "$CONFIG_DIR"

write_tls_config() {
  local ips=""
  ips=$(echo "$HOSTNAME_IP_MAP" | jq -r --argjson count "$SERVER_COUNT" 'to_entries[:$count] | .[].value')

  echo "tls-san:" >> "$CONFIG_FILE"
  for ip in $ips; do
    echo "  - \"$ip\"" >> "$CONFIG_FILE"
  done

  echo "  - \"${cp_hostname}.${DOMAIN}\"" >> "$CONFIG_FILE"

  if [[ "$DEPLOYMENT" = "cluster" ]]; then
    echo "  - \"${NETWORK}.${VIP}\"" >> "$CONFIG_FILE"
  fi
}

write_config() {
  local role="$1"
  local cp_hostname="$HOSTNAME"
  local advertise_ip="$HOST_IP"
  local tls_san_entries=""
  
  if [[ "$DEPLOYMENT" == "cluster" ]]; then
    cp_hostname="$VIP_HOSTNAME"
    advertise_ip="${NETWORK}.${VIP}"
  fi

  case "$role" in
    first)
      cat > "$CONFIG_FILE" <<EOF
write-kubeconfig-mode: "0644"
bind-address: ${advertise_ip}
advertise-address: ${advertise_ip}
node-ip: ${HOST_IP}
EOF

write_tls_config
      ;;
    server)
      cat > "$CONFIG_FILE" <<EOF
server: https://${cp_hostname}.${DOMAIN}:9345
token: $(cat "$NODE_TOKEN_FILE")
node-ip: ${HOST_IP}
EOF

write_tls_config
      ;;
    agent)
      cat > "$CONFIG_FILE" <<EOF
server: https://${VIP_HOSTNAME}.${DOMAIN}:9345
token: $(cat "$NODE_TOKEN_FILE")
node-ip: ${HOST_IP}
EOF
  esac
}

install_rke2() {
  local type="$1"
  local rke2_url="https://get.rke2.io"
  curl -sfL "$rke2_url" | INSTALL_RKE2_TYPE="${type}" sh -
}

setup_rke2() {
  local first_server additional_servers vip_ok ingress_ok
  first_server="$(echo "${HOSTNAME_IP_MAP}" | jq -r 'to_entries[0].key')"
  additional_servers="$(echo "${HOSTNAME_IP_MAP}" | jq -r --argjson count "$SERVER_COUNT" 'to_entries[1:$count] | .[].key')"

  if [ "$HOSTNAME" = "$first_server" ]; then
    [ -f "$CONFIG_FILE" ] || write_config first

      # add the cluster ip to the vip interface to get the control plane node bootstrapped
      if [[ "$DEPLOYMENT" = "cluster" ]]; then
        ip addr add "${NETWORK}.${VIP}"/24 dev eth1
      fi

      install_rke2 server
      start_service rke2-server

      if [[ "$DEPLOYMENT" = "cluster" ]]; then
        install_kubevip
        while true; do
          # check for the kube-vip VIP on the cluster interface
          if ip addr show "$VIP_INTERFACE" | grep -q "inet ${NETWORK}.${VIP}/32"; then
            vip_ok=0
          else
            vip_ok=1
          fi

          # Check if ingress-nginx-controller pod is healthy
          if "$BIN_DIR"/kubectl --kubeconfig="${CONFIG_DIR}/rke2.yaml" get pods -n kube-system \
            --field-selector=status.phase=Running | grep -q rke2-ingress-nginx-controller; then
            ingress_ok=0
          else
            ingress_ok=1
          fi

          if [[ $vip_ok -eq 0 && $ingress_ok -eq 0 ]]; then
            # both conditions are met, it's safe to remove the /24 bootstrap IP
            echo "found ${NETWORK}.${VIP}/32 — removing /24..."
            echo "ingress-nginx-controller is healthy"
            echo "removing the /24 bootstrap IP"
            ip addr del "${NETWORK}.${VIP}/24" dev "$VIP_INTERFACE"
            break
          fi

          [[ $vip_ok -ne 0 ]] && echo "  - ${NETWORK}.${VIP}/32 not found on $VIP_INTERFACE"
          [[ $ingress_ok -ne 0 ]] && echo "  - ingress-nginx-controller not healthy"
          
          sleep 60
        done
      fi
    cp "$NODE_TOKEN" "$NODE_TOKEN_FILE"
  elif echo "$additional_servers" | grep -qx "$HOSTNAME"; then
    [ -f "$CONFIG_FILE" ] || write_config server
    install_rke2 server
    start_service rke2-server
    cp "${FILES_DIR}/$(basename "$KUBEVIP_MANIFEST")" "$KUBEVIP_MANIFEST"
  elif [[ "$HOSTNAME" != "$VIP_HOSTNAME" ]]; then
    [ -f "$CONFIG_FILE" ] || write_config agent
    install_rke2 agent
    start_service rke2-agent
  fi
}

install_kubevip() {
  local rbac_url="https://kube-vip.io/manifests/rbac.yaml"
  local kubevip_image="ghcr.io/kube-vip/kube-vip:latest"
  local containerd_sock="/run/k3s/containerd/containerd.sock"
  local vip_interface="eth1"

  curl -s "$rbac_url" > "${KUBEVIP_RBAC}"
  "${BIN_DIR}/crictl" -r "unix://${containerd_sock}" pull "${kubevip_image}"

  "${BIN_DIR}/ctr" \
    --address "${containerd_sock}" \
    --namespace k8s.io \
    run \
    --rm \
    --net-host \
    "$kubevip_image" \
    vip \
    /kube-vip manifest daemonset \
      --interface "$VIP_INTERFACE" \
      --address "${NETWORK}.${VIP}" \
      --controlplane \
      --arp \
      --leaderElection \
      --inCluster | tee "$KUBEVIP_MANIFEST"

  cp "$KUBEVIP_MANIFEST" "$FILES_DIR"
}

setup_rke2

update_profile_env "export KUBECONFIG=${CONFIG_DIR}/rke2.yaml
export PATH=\$PATH:${BIN_DIR}" "rke2-env.sh"
