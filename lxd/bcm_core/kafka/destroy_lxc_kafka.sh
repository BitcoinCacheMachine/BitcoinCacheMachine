#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    KAFKA_HOST="bcm-kafka-$(printf %02d "$HOST_ENDING")"
    ZOOKEEPER_STACK_NAME="zookeeper-$(printf %02d "$HOST_ENDING")"
    BROKER_STACK_NAME="broker-$(printf %02d "$HOST_ENDING")"


    # remove swarm services related to kafka
    if ! lxc list | grep -q "bcm-gateway-01"; then
        if lxc exec bcm-gateway-01 -- docker stack ls | grep -q "$ZOOKEEPER_STACK_NAME"; then
            lxc exec bcm-gateway-01 -- docker stack rm "$ZOOKEEPER_STACK_NAME"
        fi

        if lxc exec bcm-gateway-01 -- docker stack ls | grep -q "$BROKER_STACK_NAME"; then
            lxc exec bcm-gateway-01 -- docker stack rm "$BROKER_STACK_NAME"
        fi

    fi

    if lxc list | grep -q "$KAFKA_HOST"; then
        lxc delete "$KAFKA_HOST" --force
    fi

    if lxc storage volume list bcm_btrfs | grep -q "$KAFKA_HOST-dockerdisk"; then
        lxc storage volume delete bcm_btrfs "$KAFKA_HOST-dockerdisk" --target "$endpoint"
    fi
done


if lxc exec bcm-gateway-01 -- docker network ls | grep -q kafkanet; then
    lxc exec bcm-gateway-01 -- docker network rm kafkanet
fi

if lxc profile list | grep -q "bcm_kafka_profile"; then
    lxc profile delete bcm_kafka_profile
fi
