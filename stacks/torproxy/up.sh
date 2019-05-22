#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# first, let's make sure we deploy our direct dependencies.
if ! bcm tier list | grep -q "bitcoin$BCM_ACTIVE_CHAIN"; then
    bash -c "$BCM_GIT_DIR/project/tiers/bitcoin/up.sh"
fi

# push the stack files up tthere.
lxc file push  -p -r ./stack/ "$BCM_MANAGER_HOST_NAME"/root/torproxy

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:$BCM_VERSION"
lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$TOR_IMAGE" BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" docker stack deploy -c "/root/torproxy/stack/torproxy.yml" "torproxy-$BCM_ACTIVE_CHAIN"
