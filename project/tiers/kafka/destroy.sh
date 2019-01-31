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

fi

if [[ $BCM_DEPLOY_STACK_KAFKA_CONNECT == 1 ]]; then
	# shellcheck disable=1091
	source ./stacks/kafkaconnect/env
	bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
	BCM_STACK_NAME=
fi

# destroy the brokers and zookeeper stacks which are deployed as distinct docker services
bash -c ./broker/destroy_lxc_broker.sh
bash -c ./zookeeper/destroy_zookeeper.sh

lxc exec bcm-gateway-01 -- rm -rf /root/stacks/kafka/
