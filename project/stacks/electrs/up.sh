#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


source ./env

# first, let's make sure we deploy our direct dependencies.
if ! bcm stack list | grep -q "bitcoind"; then
    bcm stack deploy bitcoind
fi

# this is the LXC host that the docker container is going to be provisioned to.
HOST_ENDING="01"

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
source "$BCM_GIT_DIR/project/shared/env.sh" --host-ending="$HOST_ENDING"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

# 50001 for mainnet
SERVICE_PORT="$MAINNET_PORT"
if [[ "$BCM_DEFAULT_CHAIN" == "testnet" ]]; then
    SERVICE_PORT="$TESTNET_PORT"
    elif [[ "$BCM_DEFAULT_CHAIN" == "regtest" ]]; then
    SERVICE_PORT="$REGTEST_PORT"
fi

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$BCM_DEFAULT_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
SERVICE_PORT="$SERVICE_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$BCM_DEFAULT_CHAIN"
