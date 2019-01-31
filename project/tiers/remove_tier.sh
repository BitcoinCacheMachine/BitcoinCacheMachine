#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    BROKER_STACK_NAME="broker-$(printf %02d "$HOST_ENDING")"
    
    # remove swarm services related to kafka
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$BROKER_STACK_NAME"
done

if lxc list | grep -q "bcm-gateway-01"; then
    if lxc exec bcm-gateway-01 -- docker network ls | grep -q kafkanet; then
        lxc exec bcm-gateway-01 -- docker network remove kafkanet
    fi
fi


if [[ -z $BCM_TIER_NAME ]]; then
	echo "BCM_TIER_NAME is empty. Exiting"
	exit
fi

export "BCM_TIER_NAME=$BCM_TIER_NAME"

bash -c "./$BCM_TIER_NAME/destroy.sh"

# iterate over endpoints and delete actual LXC hosts.
for LXD_ENDPOINT in $(bcm cluster list --endpoints); do
	HOST_ENDING=$(echo "$LXD_ENDPOINT" | tail -c 2)
	LXC_HOST="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
	bash -c "$BCM_LXD_OPS/remove_docker_node.sh --node-name=$LXC_HOST"
	bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOST"
	bash -c "$BCM_LXD_OPS/delete_cluster_dockerdisk.sh --container-name=$LXC_HOST --endpoint=$LXD_ENDPOINT"
done

PROFILE_NAME='bcm_'"$BCM_TIER_NAME"'_profile'
if lxc profile list | grep -q "$PROFILE_NAME"; then
	lxc profile delete "$PROFILE_NAME"
fi

lxc exec bcm-gateway-01 -- rm -Rf "/root/stacks/$BCM_TIER_NAME"
