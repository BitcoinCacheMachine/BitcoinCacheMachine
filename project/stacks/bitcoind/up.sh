#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q bitcoin; then
    bcm tier create bitcoin
fi

source ./stack_env.sh

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
source "$BCM_GIT_DIR/project/shared/env.sh"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build/" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$BCM_STACKS_DIR/bitcoind/stack" "$BCM_GATEWAY_HOST_NAME/root/stacks/bitcoin/"

# get bitcoind ENV vars. This file is also
source ./env --chain="$BCM_ACTIVE_CHAIN"

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
BCM_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
BITCOIND_CHAIN_TEXT="$BITCOIND_CHAIN_TEXT" \
BITCOIND_RPC_PORT="$BITCOIND_RPC_PORT" \
BITCOIND_ZMQ_BLOCK_PORT="$BITCOIND_ZMQ_BLOCK_PORT" \
BITCOIND_ZMQ_TX_PORT="$BITCOIND_ZMQ_TX_PORT" \
STACK_GOGO_FILE="$STACK_GOGO_FILE" \
docker stack deploy -c "/root/stacks/bitcoin/stack/$STACK_FILE" "$STACK_NAME-$BCM_ACTIVE_CHAIN"

UPLOAD_BLOCKS=1
UPLOAD_CHAINSTATE=0

SRC_DIR="$HOME/.bitcoin"
DEST_DIR='/var/lib/docker/volumes/bitcoind-'"$BCM_ACTIVE_CHAIN"'_bitcoin_data/_data'
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    SRC_DIR="$HOME/.bitcoin/testnet3"
    DEST_DIR="$DEST_DIR/testnet3"
    UPLOAD_CHAINSTATE=1
    elif [[ $BCM_ACTIVE_CHAIN == 'regtest' ]]; then
    SRC_DIR="$HOME/.bitcoin/regtest"
    DEST_DIR="$DEST_DIR/regtest"
    UPLOAD_BLOCKS=0
fi

# if the $HOME/.bitcoin/blocks (or testnet3/blocks) directory exists,
# then we can use it to seed # our new full node with blocks.
# this is better because we won't have to bog the TOR network down.
if [[ ! -d "$SRC_DIR/blocks" ]]; then
    # TODO, see if we can minimize the amount of blocks to be uploaded, eg., last 300 blocks.
    UPLOAD_BLOCKS=0
else
    if [[ "$BCM_ACTIVE_CHAIN" != "regtest" ]]; then
        echo "Note: You can push the raw blockchain when the $SRC_DIR/blocks directory exists."
    fi
fi

if [[ ! -d "$SRC_DIR/chainstate" ]]; then
    UPLOAD_CHAINSTATE=0
else
    if [[ $BCM_ACTIVE_CHAIN != 'regtest' ]]; then
        echo "Note: You can push the raw chainstate when the $SRC_DIR/blocks directory exists."
    fi
fi

if [[ "$UPLOAD_BLOCKS" == 1 ]]; then
    # let's see if the gogo file is there. If so, then we've already
    # previously uploaded this stuff and we can skip the next procedure
    if ! lxc exec "$LXC_HOSTNAME" -- [ -f "$DEST_DIR/gogo" ]; then
        lxc file push -r -p "$SRC_DIR/blocks" "$LXC_HOSTNAME/$DEST_DIR"
    fi
fi

if [[ "$UPLOAD_CHAINSTATE" == 1 ]]; then
    if ! lxc exec "$LXC_HOSTNAME" -- [ -f "$DEST_DIR/gogo" ]; then
        lxc file push -r -p "$SRC_DIR/chainstate" "$LXC_HOSTNAME/$DEST_DIR"
    fi
fi

if ! lxc exec "$LXC_HOSTNAME" -- [ -f "$DEST_DIR/gogo" ]; then
    lxc exec "$LXC_HOSTNAME" -- mkdir -p "$DEST_DIR"
    lxc exec "$LXC_HOSTNAME" -- touch "$DEST_DIR/gogo"
fi