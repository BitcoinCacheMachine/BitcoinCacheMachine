#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PUBLIC_SCHEMA_REGISTRY_IMAGE="confluentinc/cp-schema-registry:5.0.1"
SCHEMA_REGISTRY_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-kafka-schema-registry:latest"

lxc exec bcm-kafka-01 -- docker pull $PUBLIC_SCHEMA_REGISTRY_IMAGE
lxc exec bcm-kafka-01 -- docker tag $PUBLIC_SCHEMA_REGISTRY_IMAGE "$SCHEMA_REGISTRY_IMAGE"
lxc exec bcm-kafka-01 -- docker push "$SCHEMA_REGISTRY_IMAGE"


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