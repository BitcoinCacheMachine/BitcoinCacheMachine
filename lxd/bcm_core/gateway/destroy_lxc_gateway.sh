#!/bin/bash

set -eu
cd "$(dirname "$0")"


MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    #echo $endpoint
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    GATEWAY_HOST="bcm-gateway-$(printf %02d $HOST_ENDING)"

    if [[ ! -z $(lxc list | grep "$GATEWAY_HOST") ]]; then
        lxc delete $GATEWAY_HOST --force
    fi

    if [[ ! -z $(lxc storage volume list bcm_btrfs | grep "$GATEWAY_HOST-dockerdisk") ]]; then
        lxc storage volume delete bcm_btrfs "$GATEWAY_HOST-dockerdisk" --target $endpoint
    fi
done

BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE=0
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



if [[ ! -z $(lxc image list | grep "bcm-gateway-template") ]]; then
    # this deletes the image from the cluster.
    lxc image delete bcm-gateway-template
fi

# delete the profile bcm_gateway_profile
if [[ ! -z $(lxc profile list | grep "bcm_gateway_profile") ]]; then
    lxc profile delete bcm_gateway_profile
fi
