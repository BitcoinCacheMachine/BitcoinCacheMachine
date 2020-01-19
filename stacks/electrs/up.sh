#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env.sh

# first, let's make sure we deploy our direct dependencies.
if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep -q "$STACK_NAME" | grep -q "bitcoind"; then
    bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=bitcoind"
fi

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

source "$BCM_STACKS_DIR/bitcoind/env.sh"
source ./env.sh

lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
ELECTRS_RPC_PORT="$ELECTRS_RPC_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"
