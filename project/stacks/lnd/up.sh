#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env.sh

# first, let's make sure we deploy our direct dependencies.
bcm stack deploy bitcoind

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
source "$BCM_GIT_DIR/project/shared/env.sh"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

source "$BCM_GIT_DIR/project/stacks/bitcoind/env"
source ./env

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
CHAIN_TEXT="$CHAIN_TEXT" \
BITCOIND_RPC_PORT="$BITCOIND_RPC_PORT" \
BITCOIND_ZMQ_BLOCK_PORT="$BITCOIND_ZMQ_BLOCK_PORT" \
BITCOIND_ZMQ_TX_PORT="$BITCOIND_ZMQ_TX_PORT" \
BITCOIND_RPC_USERNAME="bitcoin" \
BITCOIND_RPC_PASSWORD="password" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$BCM_ACTIVE_CHAIN"
