#!/usr/bin/env bash

set -eu

# let's install and configure docker-ce
if [[ -z $(snap list | grep docker) ]]; then
    if [[ -z $(groups | grep docker) ]]; then
        sudo addgroup --system docker
        sudo adduser $(whoami) docker
    fi
    
    sudo snap install docker --stable

    sudo snap disable docker
    sudo snap enable docker
fi

# install ZFS locally and client tools.
sudo apt-get update
sudo apt-get install -y zfsutils-linux wait-for-it rsync apg libfuse-dev fuse

# remove any legacy lxd software and install install lxd via snap
if [[ -z $(snap list | grep lxd) ]]; then
   
    # if the lxd groups doesn't exist, create it.
    if [[ -z $(cat /etc/group | grep lxd) ]]; then
        sudo addgroup --system lxd
    fi

    # add the current user to the lxd group if necessary
    if [[ -z $(groups $(whoami) | grep lxd) ]]; then
        sudo adduser $(whoami) lxd
        newgrp lxd -
    fi

    sudo snap install lxd --stable

    # next let's configure the software.
    bash -c "./provision_lxd.sh"
fi

# Next make sure multipass is installed so we can run type-1 VMs
if [[ -z $(snap list | grep multipass) ]]; then
    # if it doesn't, let's install
    sudo snap install multipass --beta --classic
fi