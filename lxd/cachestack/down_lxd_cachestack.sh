#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision Cache Stack
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

lxc list >>/dev/null


# delete lxd container cachestack
if [[ $(lxc list | grep cachestack) ]]; then
    echo "Deleting lxd container 'cachestack'."
    lxc delete --force cachestack >/dev/null
fi


# delete lxd container cachestack
if [[ $(lxc profile list | grep cachestackprofile) ]]; then
    echo "Deleting lxd profile 'cachestackprofile'."
    lxc profile delete cachestackprofile >/dev/null
fi


# delete lxd network lxdbrCacheStack 
if [[ $(lxc network list | grep lxdbrCacheStack) ]]; then
    echo "Deleting lxd network 'lxdbrCacheStack'."
    lxc network delete lxdbrCacheStack
fi


# delete lxd network lxdBCSMgrnet 
if [[ $(lxc network list | grep lxdBCSMgrnet) ]]; then
    echo "Deleting lxd network 'lxdBCSMgrnet'."
    lxc network delete lxdBCSMgrnet
fi

# delete lxd network lxdBrNowhere 
if [[ $(lxc network list | grep lxdBrNowhere) ]]; then
    echo "Deleting lxd network 'lxdBrNowhere'."
    lxc network delete lxdBrNowhere
fi

# if the user has instructed us to delete the dockervol backing.
if [[ $BCM_CACHESTACK_DOCKERVOL_DELETE = "true" ]]; then
    # delete lxd storage cachestack-dockervol 
    if [[ $(lxc storage list | grep "cachestack-dockervol") ]]; then
        echo "Deleting lxd storage pool 'cachestack-dockervol'."
        lxc storage delete cachestack-dockervol
    fi
fi

