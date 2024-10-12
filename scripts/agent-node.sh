#!/bin/bash

set -euxo pipefail

RKE2_CONFIG_FOLDER=/etc/rancher/rke2
RKE2_CONFIG_FILE=config.yaml
RKE2_NODE_TOKEN_FILE=/vagrant/files/node-token

createRKE2Config() {
  if [ ! -d $RKE2_CONFIG_FOLDER ]; then
    mkdir -p $RKE2_CONFIG_FOLDER
  fi

  if [ ! -f $RKE2_CONFIG_FOLDER/$RKE2_CONFIG_FILE ]; then
    cat > $RKE2_CONFIG_FOLDER/$RKE2_CONFIG_FILE <<EOF
server: https://${SERVER_NODE_HOSTNAME}.${DOMAIN}:9345
token: $(cat $RKE2_NODE_TOKEN_FILE)
node-ip: ${NETWORK}${NODE_START}
EOF
  fi
}

installRKE2() {
  curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
  systemctl enable rke2-agent.service
  systemctl start rke2-agent.service
}

createRKE2Config
installRKE2