#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PUBLIC_KAFKA_CONNECT_IMAGE="confluentinc/cp-kafka-connect:5.0.1"
KAFKA_CONNECT_IMAGE="$PRIVATE_REGISTRY/bcm-kafka-connect:latest"

lxc exec bcm-kafka-01 -- docker pull $PUBLIC_KAFKA_CONNECT_IMAGE
lxc exec bcm-kafka-01 -- docker tag $PUBLIC_KAFKA_CONNECT_IMAGE "$KAFKA_CONNECT_IMAGE"
lxc exec bcm-kafka-01 -- docker push "$KAFKA_CONNECT_IMAGE"

# now let's deploy kafka
lxc file push ./kafka-connect.yml bcm-gateway-01/root/stacks/kafka-connect.yml

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$KAFKA_CONNECT_IMAGE" KAFKA_BOOSTRAP_SERVERS=$KAFKA_BOOSTRAP_SERVERS ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" docker stack deploy -c /root/stacks/kafka-connect.yml kafkaconnect
