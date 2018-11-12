#!/bin/bash

# install ZFS locally and client tools.


# sudo apt-get update
# sudo apt-get install -y zfsutils-linux wait-for-it apg
# sudo apt-get remove lxd lxd-client

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

    # usually good to wait before exiting; other tools may try to use the tool
    # before its initiailzed.
    sleep 10
fi
