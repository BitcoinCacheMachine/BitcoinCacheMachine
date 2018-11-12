#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh



for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    #echo $endpoint
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME=bcm-gateway-$(printf %02d $HOST_ENDING)
    # let's kill a bcm-gateway LXC instance on each cluster endpoint.
    if [[ ! -z $(lxc list | grep $LXD_CONTAINER_NAME) ]]; then
        lxc delete $LXD_CONTAINER_NAME --force
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



# this deletes the image from the cluster.
lxc image delete bcm-gateway-template


# delete the profile bcm-gateway-profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE = 1 ]]; then
    if [[ ! -z $(lxc profile list | grep "bcm-gateway-profile") ]]; then
        lxc profile delete bcm-gateway-profile
    fi
fi