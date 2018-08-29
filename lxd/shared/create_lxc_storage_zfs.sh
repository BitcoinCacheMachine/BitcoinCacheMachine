#!/bin/bash

set -e

if [[ $1 = "true" ]]; then
    # create the zfs storage pool bcm_data
    if [[ -z $(lxc storage list | grep $2) ]]; then
        lxc storage create $2 zfs size=$3
    else
        echo "LXC storage pool '$2' already exists, skipping pool creation."
    fi
fi