#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list endpoints); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    BROKER_STACK_NAME="broker-$(printf %02d "$HOST_ENDING")"
    
    # remove swarm services related to kafka
      if lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack ls --format "{{.Name}}" | grep -q "$BROKER_STACK_NAME"; then
            lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack remove "$BROKER_STACK_NAME"
            sleep 20
        fi
done

if lxc list | grep -q "$BCM_MANAGER_HOST_NAME"; then
    if lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network ls | grep -q kafkanet; then
        lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network remove kafkanet
    fi
fi
