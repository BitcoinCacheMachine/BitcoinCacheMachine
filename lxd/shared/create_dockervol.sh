#!/bin/bash

set -e

if [ "$1" = "" ]; then
    echo "LXD hostname not passed. Quitting."
    exit 1
fi

LXC_HOSTNAME=$1

# create the {host}-dockervol storage pool.
if [[ -z $(lxc storage list | grep "$LXC_HOSTNAME-dockervol") ]]; then
    # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
    echo "Creating a dockervol for 'bcm-gateway'."
    lxc storage create $LXC_HOSTNAME-dockervol dir

    echo "Adding dockerdisk device to $LXC_HOSTNAME. /var/lib/docker in the container '$LXC_HOSTNAME' maps to the lxc storage pool '$LXC_HOSTNAME-dockervol'."
    lxc config device add $LXC_HOSTNAME dockerdisk disk source=$(lxc storage show $LXC_HOSTNAME-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
# else
#     echo "LXC storage pool '$LXC_HOSTNAME-dockervol' already exists; attaching it to LXD container '$LXC_HOSTNAME'."
#     lxc config device add $LXC_HOSTNAME dockerdisk disk source=$(lxc storage show $LXC_HOSTNAME-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
fi