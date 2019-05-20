#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# first, let's make sure we deploy our direct dependencies.
if ! bcm tier list | grep -q "bitcoin$BCM_ACTIVE_CHAIN"; then
    bcm tier create bitcoin
fi

# push the stack files up tthere.
lxc file push  -p -r ./build/ "$BCM_BITCOIN_HOST_NAME"/root/torproxy

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:$BCM_VERSION"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker build \
--build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" \
--build-arg BCM_PRIVATE_REGISTRY="$BCM_PRIVATE_REGISTRY" \
-t "$TOR_IMAGE" "/root/torproxy/build"

lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker push "$TOR_IMAGE"

# push the stack files up tthere.
lxc file push  -p -r ./stack/ "$BCM_MANAGER_HOST_NAME"/root/torproxy

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c "/root/torproxy/stack/torproxy.yml" "torproxy-$BCM_ACTIVE_CHAIN"
