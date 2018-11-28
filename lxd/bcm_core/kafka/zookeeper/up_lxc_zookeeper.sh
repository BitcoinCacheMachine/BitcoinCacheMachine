#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

ZOOKEEPER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-zookeeper:latest"
KAFKA_HOSTNAME="bcm-kafka-01"
SOURCE_ZOOKEEPER_IMAGE="zookeeper:3.4.13"

if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
    lxc exec $KAFKA_HOSTNAME -- docker pull $SOURCE_ZOOKEEPER_IMAGE
    lxc exec $KAFKA_HOSTNAME -- docker tag $SOURCE_ZOOKEEPER_IMAGE "$ZOOKEEPER_IMAGE"
    lxc exec $KAFKA_HOSTNAME -- docker push "$ZOOKEEPER_IMAGE"
fi
 
if ! lxc exec bcm-gateway-01 -- docker network list | grep -q "zookeepernet"; then
    lxc exec bcm-gateway-01 -- docker network create --driver overlay --opt encrypted --attachable zookeepernet
fi

NODE=1

lxc file push -p ./zookeeper.yml bcm-gateway-01/root/stacks/kafka/zookeeper.yml

for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    if [[ "$NODE" -ge "$MAX_ZOOKEEPER_NODES" ]]; then
        break;
    fi
    
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    KAFKA_HOSTNAME="bcm-kafka-$(printf %02d "$HOST_ENDING")"

    lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$ZOOKEEPER_IMAGE" ZOOKEEPER_HOSTNAME="zookeeper-$(printf %02d "$HOST_ENDING")" OVERLAY_NETWORK_NAME="zookeeper-$(printf %02d "$HOST_ENDING")" TARGET_HOST="$KAFKA_HOSTNAME" ZOOKEPER_ID="$HOST_ENDING" ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS" docker stack deploy -c /root/stacks/kafka/zookeeper.yml "zookeeper-$(printf %02d "$HOST_ENDING")"

    NODE=$(( "$NODE" + 1 ))
done