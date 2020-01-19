#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


# let's make sure the toronion is available first.
if lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep -q "$STACK_NAME" | grep -q toronion; then
    bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=toronion"
fi

# push the stack files up tthere.
lxc file push  -p -r ./stack/ "$BCM_MANAGER_HOST_NAME"/root/torproxy

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:$BCM_VERSION"
lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$TOR_IMAGE" BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" docker stack deploy -c "/root/torproxy/stack/torproxy.yml" "torproxy-$BCM_ACTIVE_CHAIN"
