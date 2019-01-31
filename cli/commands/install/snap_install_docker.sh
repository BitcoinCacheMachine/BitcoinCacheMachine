#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# let's install and configure docker-ce
if ! snap list | grep -q docker; then
    sudo snap install docker --candidate
fi

if ! grep -q docker /etc/group; then
    sudo addgroup docker
fi

if groups "$USER" | grep -q docker; then
    sudo usermod -aG docker $USER
    sudo cp ./overlay_daemon.json /var/snap/docker/current/config/daemon.json
    sudo snap restart docker
fi