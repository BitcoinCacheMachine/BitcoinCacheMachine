#!/bin/bash

# let's attach storage to a container
set -e

#echo "Condition: $1"
#echo "Container Name: $2"
#echo "Dockervol Name: $3"

# check to ensure the container exists.
if [[ $1 = "true" ]]; then
    # only create it if it doesn't already exist.
    if [[ -z $(lxc storage list | grep $2) ]]; then
        lxc storage create $3 dir
    fi

    # let's proceed only if the container exists
    if [[ $(lxc list | grep $2) ]]; then
        #let's proceed only if the  storage volume exists
        if [[ -z $(lxc storage list | grep $3) ]]; then
            echo "Adding dockerdisk device to '$2'. /var/lib/docker in the container '$2' maps to the lxc storage pool '$3'."
            lxc config device add $2 dockerdisk disk source=$(lxc storage show $3 | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
        else
            echo "LXC storage pool '$3' already exists; attaching it to lxc container '$2'."
            lxc config device add $2 dockerdisk disk source=$(lxc storage show $3 | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
        fi
    fi
fi