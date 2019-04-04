#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


source ./env

# first, let's make sure we deploy our direct dependencies.
if ! bcm stack list | grep -q "bitcoind"; then
    bcm stack deploy bitcoind
fi

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
source "$BCM_GIT_DIR/project/shared/env.sh"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--docker-hub-image-name="$DOCKER_HUB_IMAGE" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

BITCOIND_RPCPORT=18332
BITCOIND_P2PPORT=18333


lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$(bcm get-chain)" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
BITCOIND_RPCPORT="$BITCOIND_RPCPORT" \
BITCOIND_P2PPORT="$BITCOIND_P2PPORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$(bcm get-chain)"
