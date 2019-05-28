#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PUBLIC_BROKER_IMAGE="confluentinc/cp-kafka:5.2.1"
BROKER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-broker:$BCM_VERSION"

# if it's the first instance, let's download the kafka image from
# docker hub; then we tag and push to our local private registry
# so subsequent kafka nodes can just download from there.

lxc exec "$BCM_MANAGER_HOST_NAME" -- docker pull "$PUBLIC_BROKER_IMAGE"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker tag "$PUBLIC_BROKER_IMAGE" "$BROKER_IMAGE"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker push "$BROKER_IMAGE"

if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network list | grep "kafkanet" | grep "overlay" | grep -q "swarm"; then
    lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network create --driver=overlay --opt=encrypted --attachable=true kafkanet
fi

lxc file push -p ./broker.yml "$BCM_MANAGER_HOST_NAME"/root/stacks/kafka/broker.yml

# let's deploy a kafka node to each cluster endpoint.
for ENDPOINT in $(bcm cluster list endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    BROKER_HOSTNAME="broker-$(printf %02d "$HOST_ENDING")"
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    # shellcheck source=../../project/shared/env.sh
    #source "$BCM_GIT_DIR/project/shared/env.sh" --host-ending="$HOST_ENDING"
    
    lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$BROKER_IMAGE" BROKER_HOSTNAME="$BROKER_HOSTNAME" KAFKA_BROKER_ID="$HOST_ENDING" KAFKA_ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" TARGET_HOST="$BCM_KAFKA_HOST_NAME" docker stack deploy -c /root/stacks/kafka/broker.yml "$BROKER_HOSTNAME"
done
