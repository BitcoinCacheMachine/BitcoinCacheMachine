#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# remove any legacy lxd software and install install lxd via snap
if ! snap list | grep -q lxd; then
    sudo snap install lxd --edge
    sleep 10
fi

# if the lxd groups doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup lxd
fi

if groups "$USER" | grep -q lxd; then
    sudo gpasswd -a "${USER}" lxd
    sudo snap restart lxd
fi