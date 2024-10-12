#!/bin/bash

set -euxo pipefail

PASSWORD_FILE=/vagrant/files/password.txt

installAddOnPackages() {
  apt-get -y install open-iscsi nfs-common
}

updateHostsFile() {
  echo "${SERVER_IP} ${SERVER_NODE_HOSTNAME}.${DOMAIN}" >> /etc/hosts
}

createSupportUser() {
  if ! id ${SUPPORT_USER} >/dev/null 2>&1; then
    useradd ${SUPPORT_USER} -G sudo -m -s /bin/bash
    printf "User ${SUPPORT_USER} created."
  fi

  if [ ! -f $PASSWORD_FILE ]; then
    RANDOM_PW=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8; echo)
    echo $RANDOM_PW > $PASSWORD_FILE
  fi

  RANDOM_PW=$(cat $PASSWORD_FILE)
  echo "$SUPPORT_USER:$RANDOM_PW" | chpasswd
}

installAddOnPackages
updateHostsFile
createSupportUser