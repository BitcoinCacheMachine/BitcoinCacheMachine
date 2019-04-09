#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


source ./env

bcm stack deploy bitcoind

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

BITCOIND_RPC_PORT="8332"
BITCOIND_P2P_PORT="8333"
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    BITCOIND_RPC_PORT="18332"
    BITCOIND_P2P_PORT="18333"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    BITCOIND_RPC_PORT="28332"
    BITCOIND_P2P_PORT="28333"
fi


lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
BITCOIND_RPCPORT="$BITCOIND_RPC_PORT" \
BITCOIND_P2PPORT="$BITCOIND_P2P_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$BCM_ACTIVE_CHAIN"
