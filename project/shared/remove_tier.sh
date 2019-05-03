#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            TIER_NAME="${i#*=}"
            shift # past argument=value
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

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
# Get the $PROFILE_NAME from env.sh
source ./env.sh

# iterate over endpoints and delete actual LXC hosts.
for LXD_ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$LXD_ENDPOINT" | tail -c 2)
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    source ./env.sh --host-ending="$HOST_ENDING"
    
    if [[ "$LXC_HOSTNAME" != "$BCM_GATEWAY_HOST_NAME" ]]; then
        # we are only going to remove the node if it's not the "$BCM_GATEWAY_HOST_NAME" node, which is special.
        bash -c "$BCM_LXD_OPS/remove_docker_node.sh --node-name=$LXC_HOSTNAME"
    fi
    
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOSTNAME"
    bash -c "$BCM_LXD_OPS/delete_dockerdisk.sh --container-name=$LXC_HOSTNAME --endpoint=$LXD_ENDPOINT"
done

if lxc profile list --format csv | grep "$PROFILE_NAME" | grep -q ",0" ; then
    lxc profile delete "$PROFILE_NAME"
fi
