#!/bin/bash

set -eu

LXC_CONTAINER_NAME=
LXC_DOCKERVOL_NAME=

for i in "$@"
do
case $i in
    --container-name=*)
    LXC_CONTAINER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

LXC_DOCKERVOL_NAME="$LXC_CONTAINER_NAME-dockervol"

if [[ -z $LXC_CONTAINER_NAME ]]; then
    echo "ERROR: BCM_LXC_CONTAINER_NAME was not set. Cannot create a dockervol storage backing."
    exit
fi

if [[ -z $BCM_CLUSTER_NAME ]]; then
    echo "ERROR: BCM_CLUSTER_NAME was empty. Can't create/attach a dockervol."
    exit
fi

# let's proceed only if the container exists
if [[ ! $(lxc list | grep $LXC_CONTAINER_NAME) ]]; then
    echo "Error. There is no LXC container named '$LXC_CONTAINER_NAME'"
    exit
fi

#let's proceed only if the  storage volume exists
if [[ ! -z $(lxc storage list | grep "$LXC_DOCKERVOL_NAME") ]]; then
    echo "Adding dockerdisk device to '$LXC_CONTAINER_NAME'. /var/lib/docker in the container '$LXC_CONTAINER_NAME' maps to the lxc storage pool '$LXC_DOCKERVOL_NAME'."
    lxc config device add $LXC_CONTAINER_NAME dockerdisk disk source="$(lxc storage show $LXC_DOCKERVOL_NAME | grep 'source' | awk 'NF>1{print $NF}')" path=/var/lib/docker
fi
