#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# let's install and configure docker-ce
if ! snap list | grep -q docker; then
    sudo snap install docker --stable
fi

if ! grep -q docker /etc/group; then
    sudo addgroup docker
fi

if groups "$USER" | grep -q docker; then
    sudo gpasswd -a "$USER" docker
    #newgrp docker -
    sudo cp ./daemon.json /var/snap/docker/current/config/daemon.json
    sudo snap restart docker
fi
