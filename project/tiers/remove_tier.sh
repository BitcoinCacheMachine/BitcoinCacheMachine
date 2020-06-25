#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            TIER_NAME="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $TIER_NAME ]]; then
    echo "TIER_NAME is empty. Exiting"
    exit
fi

PROFILE_NAME="bcm-$TIER_NAME"
if [[ $TIER_NAME == bitcoin* ]]; then
    PROFILE_NAME="bcm-bitcoin"
fi

# iterate over endpoints and delete actual LXC hosts.
for LXD_ENDPOINT in $CLUSTER_ENDPOINTS; do
    HOST_ENDING=$(echo "$LXD_ENDPOINT" | tail -c 2)
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    source ./env.sh --host-ending="$HOST_ENDING"
    
    if [[ "$LXC_HOSTNAME" != "$BCM_MANAGER_HOST_NAME" ]]; then
        # we are only going to remove the node if it's not the "$BCM_MANAGER_HOST_NAME" node, which is special.
        bash -c "$BCM_LXD_OPS/remove_docker_node.sh --node-name=$LXC_HOSTNAME"
    fi
    
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOSTNAME"
    
    CONTAINER_NAME="$LXC_HOSTNAME"
    if [[ $LXC_HOSTNAME == *"-bitcoin-"* ]]; then
        CONTAINER_NAME="bcm-bitcoin-$BCM_ACTIVE_CHAIN-$(printf %02d "$HOST_ENDING")"
    fi
    
    bash -c "$BCM_LXD_OPS/delete_dockerdisk.sh --container-name=$CONTAINER_NAME --endpoint=$LXD_ENDPOINT"
done

if lxc profile list --format csv | grep "$PROFILE_NAME" | grep -q ",0" ; then
    lxc profile delete "$PROFILE_NAME"
fi
