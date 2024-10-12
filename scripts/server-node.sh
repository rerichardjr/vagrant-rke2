#!/bin/bash

set -euxo pipefail

RKE2_NODE_TOKEN=/var/lib/rancher/rke2/server/node-token
RKE2_NODE_TOKEN_FILE=/vagrant/files/node-token
RKE2_CONFIG_FOLDER=/etc/rancher/rke2
RKE2_CONFIG_FILE=config.yaml

createRKE2Config() {
  if [ ! -d $RKE2_CONFIG_FOLDER ]; then
    mkdir -p $RKE2_CONFIG_FOLDER
  fi

  if [ ! -f $RKE2_CONFIG_FOLDER/$RKE2_CONFIG_FILE ]; then
    cat > $RKE2_CONFIG_FOLDER/$RKE2_CONFIG_FILE <<EOF
write-kubeconfig-mode: "0644"
bind-address: ${SERVER_IP}
advertise-address: ${SERVER_IP}
node-ip: ${SERVER_IP}
tls-san:
  - "${DOMAIN}"
EOF
  fi
}

installRKE2() {
  curl -sfL https://get.rke2.io | sh -
  systemctl enable rke2-server.service
  systemctl start rke2-server.service
}

copyRKE2Token() {
  if [ $HOSTNAME == ${SERVER_NODE_HOSTNAME} ]; then
    cp $RKE2_NODE_TOKEN $RKE2_NODE_TOKEN_FILE
  fi
}

configureRKE2Env() {
  if [[ ! -f /usr/local/bin/kubectl ]]; then
    sudo ln -s $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl
  fi
  echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH="$PATH:/usr/local/bin/:/var/lib/rancher/rke2/bin/"' >> ~/.bashrc
  sudo -u vagrant echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH="$PATH:/usr/local/bin/:/var/lib/rancher/rke2/bin/"' >> /home/vagrant/.bashrc
  sudo -u ${SUPPORT_USER} echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH="$PATH:/usr/local/bin/:/var/lib/rancher/rke2/bin/"' >> /home/${SUPPORT_USER}/.bashrc
  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH="$PATH:/usr/local/bin/:/var/lib/rancher/rke2/bin/"
}

createRKE2Config
installRKE2
copyRKE2Token
configureRKE2Env