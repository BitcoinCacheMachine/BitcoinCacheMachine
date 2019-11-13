#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PUBLIC_BROKER_IMAGE="confluentinc/cp-kafka:5.3.1"
BROKER_IMAGE="bcm-broker"

bash -c "$BCM_LXD_OPS/docker_image_ops.sh --docker-hub-image-name=$PUBLIC_BROKER_IMAGE --container-name=$BCM_KAFKA_HOST_NAME --image-name=$BROKER_IMAGE"

if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network list | grep "kafkanet" | grep "overlay" | grep -q "swarm"; then
    lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network create --driver=overlay --opt=encrypted --attachable=true kafkanet
fi

lxc file push -p ./broker.yml "$BCM_MANAGER_HOST_NAME"/root/stacks/kafka/broker.yml

# let's deploy a kafka node to each cluster endpoint.
for ENDPOINT in $CLUSTER_ENDPOINTS; do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    BROKER_HOSTNAME="broker-$(printf %02d "$HOST_ENDING")"
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    # shellcheck source=BCM_LXD_OPS/env.sh
    source "$BCM_GIT_DIR/project/tiers/env.sh" --host-ending="$HOST_ENDING"
    
    lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$BROKER_IMAGE:$BCM_VERSION" BROKER_HOSTNAME="$BROKER_HOSTNAME" KAFKA_BROKER_ID="$HOST_ENDING" KAFKA_ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" TARGET_HOST="$BCM_KAFKA_HOST_NAME" docker stack deploy -c /root/stacks/kafka/broker.yml "$BROKER_HOSTNAME"
done
