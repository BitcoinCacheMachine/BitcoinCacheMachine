#!/bin/bash

set -Eeu

if groups "$USER" | grep -q lxd; then
    sudo deluser "${USER}" lxd
fi

# if the lxd groups exists, create it.
if grep -q lxd /etc/group; then
    sudo delgroup --system lxd
fi

if lxc profile list | grep -q "bcm_default"; then
    lxc profile delete bcm_default
fi

if lxc storage list | grep -q "bcm_btrfs"; then
    lxc storage delete bcm_btrfs
fi
