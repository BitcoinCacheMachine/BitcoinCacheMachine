#!/usr/bin/env bash

LXC_STORAGE_POOL_NAME=$1

# delete lxd storage gateway 
if [[ $(lxc storage list | grep $LXC_STORAGE_POOL_NAME) ]]; then
    echo "Deleting lxd storage pool '$LXC_STORAGE_POOL_NAME'."
    lxc storage delete $LXC_STORAGE_POOL_NAME
fi