#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PUBLIC_KAFKA_REST_IMAGE="confluentinc/cp-kafka-rest:5.0.1"
KAFKA_REST_IMAGE="$PRIVATE_REGISTRY/bcm-kafka-rest:latest"

lxc exec bcm-kafka-01 -- docker pull $PUBLIC_KAFKA_REST_IMAGE
lxc exec bcm-kafka-01 -- docker tag $PUBLIC_KAFKA_REST_IMAGE "$KAFKA_REST_IMAGE"
lxc exec bcm-kafka-01 -- docker push "$KAFKA_REST_IMAGE"

# now let's deploy kafka
lxc file push ./kafka-rest.yml bcm-gateway-01/root/stacks/kafka-rest.yml

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$KAFKA_REST_IMAGE" ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" docker stack deploy -c /root/stacks/kafka-rest.yml kafkarest

# let's scale the schema registry count to UP TO 3.
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    REPLICAS=$CLUSTER_NODE_COUNT

    if [[ $CLUSTER_NODE_COUNT -ge 3 ]]; then
        REPLICAS=3
    fi

    lxc exec bcm-gateway-01 -- docker service scale kafkarest_kafka-rest="$REPLICAS"
fi