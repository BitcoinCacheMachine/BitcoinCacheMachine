#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./env

# we get the hostname of the LXD container by getting its endpoint ID (which endpoint it's scheduled on)
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # remove the host number from the hostname
    LXC_HOST=${BCM_GATEWAY_HOST_NAME::-3}
    LXC_HOST="$LXC_HOST-$(printf %02d "$HOST_ENDING")"
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOST"
    bash -c "$BCM_LXD_OPS/delete_dockerdisk.sh --container-name=$LXC_HOST --endpoint=$ENDPOINT"
done

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmbrGWNat"

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmNet"

bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-gateway-template"

bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=bcm_gateway_profile"