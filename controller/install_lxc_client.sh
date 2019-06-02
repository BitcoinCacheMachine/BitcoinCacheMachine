#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# install LXD if it doesn't exist.
if [ ! -x "$(command -v lxc)" ]; then
    # if the lxd groups doesn't exist, create it.
    if ! grep -q lxd /etc/group; then
        sudo addgroup --system lxd
    fi
    
    if ! groups "$USER" | grep -q lxd; then
        sudo adduser "${USER}" lxd
        sudo gpasswd -a "${USER}" lxd
    fi
    
    if [ ! -x "$(command -v lxd)" ]; then
        sudo snap install lxd --channel=candidate
        sudo snap set system snapshots.automatic.retention=no
        sudo lxd init --auto --network-address=127.0.1.1 --network-port=8443 --storage-backend=btrfs
    fi
fi
