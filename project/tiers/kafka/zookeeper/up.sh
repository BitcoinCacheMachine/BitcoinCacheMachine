#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

ZOOKEEPER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-zookeeper:$BCM_VERSION"
SOURCE_ZOOKEEPER_IMAGE="zookeeper:3.5"

lxc exec "$BCM_KAFKA_HOST_NAME" -- docker pull "$SOURCE_ZOOKEEPER_IMAGE"
lxc exec "$BCM_KAFKA_HOST_NAME" -- docker tag "$SOURCE_ZOOKEEPER_IMAGE" "$ZOOKEEPER_IMAGE"
lxc exec "$BCM_KAFKA_HOST_NAME" -- docker push "$ZOOKEEPER_IMAGE"

if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network list | grep -q "zookeepernet"; then
    lxc exec "$BCM_MANAGER_HOST_NAME" -- docker network create --driver overlay --opt encrypted --attachable zookeepernet
fi

NODE=1

lxc file push -p ./zookeeper.yml "$BCM_MANAGER_HOST_NAME"/root/stacks/kafka/zookeeper.yml

for ENDPOINT in $(bcm cluster list endpoints); do
    if [[ "$NODE" -ge "$MAX_ZOOKEEPER_NODES" ]]; then
        break
    fi
    
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    # shellcheck source=../../project/shared/env.sh
    source "$BCM_GIT_DIR/project/shared/env.sh" --host-ending="$HOST_ENDING"
    
    lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$ZOOKEEPER_IMAGE" ZOOKEEPER_HOSTNAME="zookeeper-$(printf %02d "$HOST_ENDING")" OVERLAY_NETWORK_NAME="zookeeper-$(printf %02d "$HOST_ENDING")" TARGET_HOST="$LXC_HOSTNAME" ZOOKEPER_ID="$HOST_ENDING" ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS" docker stack deploy -c /root/stacks/kafka/zookeeper.yml "zookeeper-$(printf %02d "$HOST_ENDING")"
    
    NODE=$(("$NODE" + 1))
done
