#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

PUBLIC_SCHEMA_REGISTRY_IMAGE="confluentinc/cp-schema-registry:5.0.1"
SCHEMA_REGISTRY_IMAGE="$REGISTRY/bcm-kafka-schema-registry:latest"
KAFKA_HOSTNAME="bcm-kafka-01"

if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
    lxc exec $KAFKA_HOSTNAME -- docker pull $PUBLIC_SCHEMA_REGISTRY_IMAGE
    lxc exec $KAFKA_HOSTNAME -- docker tag $PUBLIC_SCHEMA_REGISTRY_IMAGE "$SCHEMA_REGISTRY_IMAGE"
    lxc exec $KAFKA_HOSTNAME -- docker push "$SCHEMA_REGISTRY_IMAGE"
fi

# now let's deploy kafka
lxc file push ./schema-registry.yml bcm-gateway-01/root/stacks/schema-registry.yml

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$SCHEMA_REGISTRY_IMAGE" KAFKA_ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" docker stack deploy -c /root/stacks/schema-registry.yml schemaregistry

# let's scale the schema registry count to UP TO 3.
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    REPLICAS=$CLUSTER_NODE_COUNT

    if [[ $CLUSTER_NODE_COUNT -ge 3 ]]; then
        REPLICAS=3
    fi

    lxc exec bcm-gateway-01 -- docker service scale schemaregistry_schema-registry="$REPLICAS"
fi