#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh


MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    #echo $endpoint
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME="bcm-gateway-$(printf %02d $HOST_ENDING)"
    #echo "HOST_ENDING: $HOST_ENDING"
    #echo "LXD_CONTAINER_NAME: $LXD_CONTAINER_NAME"
    # let's kill a bcm-gateway LXC instance on each cluster endpoint.
    if [[ $MASTER_NODE != $endpoint ]]; then
        if [[ ! -z $(lxc list | grep "$endpoint") ]]; then
            lxc delete $LXD_CONTAINER_NAME --force
        fi

        if [[ ! -z $(lxc storage volume list bcm_btrfs | grep "bcm-gateway-dockervol") ]]; then
            lxc storage volume delete bcm_btrfs bcm-gateway-dockervol --target $endpoint
        fi
    fi
done

MASTER_NODE="bcm-gateway-01"
if [[ ! -z $(lxc list | grep $MASTER_NODE) ]]; then
    lxc delete $MASTER_NODE --force
fi

if [[ ! -z $(lxc storage volume list bcm_btrfs | grep "bcm-gateway-dockervol") ]]; then
    lxc storage volume delete bcm_btrfs bcm-gateway-dockervol
fi

if [[ $BCM_REMOVE_TEMPLATE_FLAG == 1 ]]; then
    # delte container gateway-template
    if [[ $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE = 1 ]]; then
        if [[ ! -z $(lxc list | grep "bcm-template") ]]; then
            lxc delete bcm-template --force
        fi
    fi

    if [[ ! -z $(lxc network list | grep bcmbrGWNat) ]]; then
        lxc network delete bcmbrGWNat
    fi
    
    if [[ ! -z $(lxc network list | grep bcmNet) ]]; then
        lxc network delete bcmNet
    fi
fi


if [[ ! -z $(lxc image list | grep "bcm-gateway-template") ]]; then
    # this deletes the image from the cluster.
    lxc image delete bcm-gateway-template
fi

# delete the profile bcm-gateway-profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE = 1 ]]; then
    if [[ ! -z $(lxc profile list | grep "bcm-gateway-profile") ]]; then
        lxc profile delete bcm-gateway-profile
    fi
fi