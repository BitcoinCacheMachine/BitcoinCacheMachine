#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            BCM_TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $BCM_TIER_NAME ]]; then
    echo "BCM_TIER_NAME is empty. Exiting"
    exit
fi

# iterate over endpoints and delete actual LXC hosts.
for LXD_ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$LXD_ENDPOINT" | tail -c 2)
    
    LXC_HOST="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
    if [[ "$LXC_HOST" != 'bcm-gateway-01' ]]; then
        # we are only going to remove the node if it's not the bcm-gateway-01 node, which is special.
        bash -c "$BCM_LXD_OPS/remove_docker_node.sh --node-name=$LXC_HOST"
    fi
    
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOST"
    bash -c "$BCM_LXD_OPS/delete_dockerdisk.sh --container-name=$LXC_HOST --endpoint=$LXD_ENDPOINT"
done

PROFILE_NAME='bcm_'"$BCM_TIER_NAME"'_profile'
if lxc profile list | grep -q "$PROFILE_NAME"; then
    lxc profile delete "$PROFILE_NAME"
fi
