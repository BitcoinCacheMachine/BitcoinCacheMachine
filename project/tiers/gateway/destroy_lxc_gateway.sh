#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/.env"

# shellcheck disable=1091
source ./.env

for endpoint in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    LXC_HOST="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOST"
    bash -c "$BCM_LXD_OPS/delete_cluster_dockerdisk.sh --container-name=$LXC_HOST --endpoint=$endpoint"
done

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmbrGWNat"

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmNet"

bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-gateway-template"

bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=bcm_gateway_profile"
