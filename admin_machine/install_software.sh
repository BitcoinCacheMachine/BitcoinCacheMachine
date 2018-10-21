#!/usr/bin/env bash

set -eu

# let's install and configure docker-ce
if [[ ! $(snap list | grep lxd) ]]; then
    sudo snap install docker --stable

    sudo addgroup --system docker
    sudo adduser $(whoami) docker
    newgrp docker

    sudo snap disable docker
    sudo snap enable docker
fi

# install ZFS locally and client tools.
sudo apt-get update
sudo apt-get install -y zfsutils-linux wait-for-it rsync apg libfuse-dev fuse

# install lxd via snap
if [[ ! $(snap list | grep lxd) ]]; then
    sudo snap install lxd --stable
fi

# Next make sure multipass is installed so we can run type-1 VMs
if [[ ! $(snap list | grep multipass) ]]; then
    # if it doesn't, let's install
    sudo snap install multipass --beta --classic
fi
