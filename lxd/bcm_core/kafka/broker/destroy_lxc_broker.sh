#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    BROKER_STACK_NAME="broker-$(printf %02d "$HOST_ENDING")"

    # remove swarm services related to kafka
    if ! lxc list | grep -q "bcm-gateway-01"; then
        lxc exec bcm-gateway-01 -- docker stack rm "$BROKER_STACK_NAME" || true
    fi
done

if lxc list | grep -q "bcm-gateway-01"; then
    if lxc exec bcm-gateway-01 -- docker network ls | grep -q kafkanet; then
        lxc exec bcm-gateway-01 -- docker network remove kafkanet
    fi
fi