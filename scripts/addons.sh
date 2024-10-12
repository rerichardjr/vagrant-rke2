#!/bin/bash

set -euxo pipefail

node_status="kubectl get node --no-headers ${SERVER_NODE_HOSTNAME} -o custom-columns=STATUS:.status.conditions[5].type"
certmanager_status="kubectl rollout status daemonset -n kube-system rke2-ingress-nginx-controller --timeout=60s"
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH="$PATH:/usr/local/bin/:/var/lib/rancher/rke2/bin/"

installHelm() {
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  sudo DESIRED_VERSION=${HELM_VER} ./get_helm.sh
}

installCertManager() {
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGER_VER}/cert-manager.crds.yaml
  helm repo add jetstack https://charts.jetstack.io --force-update
  helm upgrade -i cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace
}

installRancher() {
  helm repo add rancher-latest https://releases.rancher.com/server-charts/${RANCHER_VER} --force-update
  helm upgrade -i rancher rancher-latest/rancher \
    --namespace cattle-system \
    --create-namespace \
    --set hostname=rancher.${SERVER_NODE_HOSTNAME}.${DOMAIN} \
    --set bootstrapPassword=admin
}

installLonghorn() {
  helm repo add longhorn https://charts.longhorn.io --force-update
  helm upgrade -i longhorn longhorn/longhorn --namespace longhorn-system --create-namespace  --version ${LONGHORN_VER}
}

checkNodeStatus() {
  until [[ $($node_status 2>/dev/null) == "Ready" ]]; do
    sleep 10
  done
}

checkCertManagerStatus() {
  while ! $certmanager_status; do 
    sleep 5
  done
}

checkNodeStatus
installHelm
installCertManager
checkCertManagerStatus
installRancher
installLonghorn