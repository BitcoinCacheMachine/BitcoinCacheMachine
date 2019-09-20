#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list endpoints); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    ZOOKEEPER_STACK_NAME="zookeeper-$(printf %02d "$HOST_ENDING")"
    
    # remove swarm services related to kafka
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$ZOOKEEPER_STACK_NAME"
done

# remove the network
if lxc list --format csv -c=n | grep -q "$BCM_MANAGER_HOST_NAME"; then
    if lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network ls | grep -q zookeepernet; then
        lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network remove zookeepernet
    fi
fi