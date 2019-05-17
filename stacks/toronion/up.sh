#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# # first, let's make sure we deploy our direct dependencies.
# if ! bcm tier list | grep -q "underlay"; then
#     bcm tier create underlay
# fi

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:$BCM_VERSION"

# push the stack files up tthere.
lxc file push  -p -r ./stack/ "$BCM_GATEWAY_HOST_NAME"/root/toronion

lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker pull "$TOR_IMAGE"

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c "/root/toronion/stack/toronion.yml" "toronion-$BCM_ACTIVE_CHAIN"
