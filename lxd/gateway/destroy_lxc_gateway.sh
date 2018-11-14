#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh

MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    #echo $endpoint
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME="bcm-gateway-$(printf %02d $HOST_ENDING)"
    echo "LXD_CONTAINER_NAME: $LXD_CONTAINER_NAME"
    if [[ ! -z $(lxc list | grep "$LXD_CONTAINER_NAME") ]]; then
        lxc delete $LXD_CONTAINER_NAME --force
    fi

    if [[ ! -z $(lxc storage volume list bcm_btrfs | grep "$LXD_CONTAINER_NAME-dockerdisk") ]]; then
        lxc storage volume delete bcm_btrfs "$LXD_CONTAINER_NAME-dockerdisk" --target $endpoint
    fi
done


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

# delete the profile bcm_gateway_profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE = 1 ]]; then
    if [[ ! -z $(lxc profile list | grep "bcm_gateway_profile") ]]; then
        lxc profile delete bcm_gateway_profile
    fi
fi