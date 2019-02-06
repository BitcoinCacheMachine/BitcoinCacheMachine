#!/bin/bash

set -Eeu

# we really only want to do these two stanzas on remote machiens...
# not for the SDN cotnroller/dev amchine.
# if groups "$USER" | grep -q lxd; then
#     sudo deluser "${USER}" lxd
# fi

# # if the lxd groups exists, create it.
# if grep -q lxd /etc/group; then
#     sudo delgroup --system lxd
# fi

if lxc image list --format csv | grep -q "bcm-template"; then
    lxc image delete bcm-template
fi

if lxc profile list | grep -q "bcm_default"; then
    lxc profile delete bcm_default
fi

if lxc storage list | grep -q "bcm_btrfs"; then
    lxc storage delete bcm_btrfs
fi
