#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env.sh

# first, let's make sure we deploy our direct dependencies.
if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep -q "$STACK_NAME" | grep -q "bitcoind"; then
    bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=bitcoind"
fi

# prepare the image.
"$BCM_LXD_OPS/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

BITCOIND_RPC_PORT="8332"
BITCOIND_P2P_PORT="8333"
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    BITCOIND_RPC_PORT="18332"
    BITCOIND_P2P_PORT="18333"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    BITCOIND_RPC_PORT="28332"
    BITCOIND_P2P_PORT="28333"
fi


lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
BITCOIND_RPCPORT="$BITCOIND_RPC_PORT" \
BITCOIND_P2PPORT="$BITCOIND_P2P_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"
