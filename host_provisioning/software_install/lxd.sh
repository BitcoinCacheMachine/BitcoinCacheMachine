#!/bin/bash

# install ZFS locally and client tools.
sudo apt-get update
sudo apt-get install -y zfsutils-linux wait-for-it rsync apg libfuse-dev fuse


# remove any legacy lxd software and install install lxd via snap
if [[ -z $(snap list | grep lxd) ]]; then
    echo "LXD snap package not found. Installing."

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
fi
