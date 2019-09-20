#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

export TIER_NAME=manager


source "$BCM_GIT_DIR/project/tiers/env.sh" 

# we get the hostname of the LXD container by getting its endpoint ID (which endpoint it's scheduled on)
for ENDPOINT in $(bcm cluster list endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # remove the host number from the hostname
    source "$BCM_GIT_DIR/project/tiers/env.sh" --host-ending="$HOST_ENDING"
    
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOSTNAME"
    bash -c "$BCM_LXD_OPS/delete_dockerdisk.sh --container-name=$LXC_HOSTNAME --endpoint=$ENDPOINT"
done

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmbrGWNat"

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmNet"

bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-manager-template"

PROFILE_NAME="bcm-manager"
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=$PROFILE_NAME"
