#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q bitcoin; then
    bcm tier create bitcoin
fi

source ./env

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

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$(bcm get-chain)" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
docker stack deploy -c "/root/stacks/bitcoin/stack/$STACK_FILE" "$STACK_NAME-$(bcm get-chain)"

UPLOAD_BLOCKS=1
UPLOAD_CHAINSTATE=0

SRC_DIR="$HOME/.bitcoin"
DEST_DIR='/var/lib/docker/volumes/bitcoind-'"$(bcm get-chain)"'_bitcoin_data/_data'
if [[ $(bcm get-chain) == "testnet" ]]; then
    SRC_DIR="$HOME/.bitcoin/testnet3"
    DEST_DIR="$DEST_DIR/testnet3"
    elif [[ $(bcm get-chain) == 'regtest' ]]; then
    SRC_DIR="$HOME/.bitcoin/regtest"
    DEST_DIR="$DEST_DIR/regtest"
fi

# if the $HOME/.bitcoin/blocks (or testnet3/blocks) directory exists,
# then we can use it to seed # our new full node with blocks.
# this is better because we won't have to bog the TOR network down.
if [[ -d "$SRC_DIR/blocks" ]]; then
    # TODO, see if we can minimize the amount of blocks to be uploaded, eg., last 300 blocks.
    UPLOAD_BLOCKS=1
else
    echo "Note: You can push the raw blockchain when the $SRC_DIR/blocks directory exists."
fi

if [[ -d "$SRC_DIR/chainstate" ]]; then
    UPLOAD_CHAINSTATE=1
fi

if [[ "$UPLOAD_BLOCKS" == 1 ]]; then
    # let's see if the gogo file is there. If so, then we've already
    # previously uploaded this stuff and we can skip the next procedure
    if ! lxc exec "$LXC_HOSTNAME" -- [ -f "$DEST_DIR/gogo" ]; then
        read -rp "Would you like to push the blocks directory for $(bcm get-chain) (y/n):  "   CHOICE
        if [[ $CHOICE == "y" ]]; then
            lxc file push -r -p "$SRC_DIR/blocks" "$LXC_HOSTNAME/$DEST_DIR"
        fi
    else
        echo "INFO: Skipping upload of blocks since it appears to have been uploaded already."
    fi
fi

if [[ "$UPLOAD_CHAINSTATE" == 1 ]]; then 
    if ! lxc exec "$LXC_HOSTNAME" -- [ -f "$DEST_DIR/gogo" ]; then
        read -rp "Would you like to push the chainstate directory for $(bcm get-chain) (y/n):  "   CHOICE
        if [[ $CHOICE == "y" ]]; then
            lxc file push -r -p "$SRC_DIR/chainstate" "$LXC_HOSTNAME/$DEST_DIR"
        fi
    else
        echo "INFO: Skipping upload of chainstate since it appears to have been uploaded already."
    fi
fi

if ! lxc exec "$LXC_HOSTNAME" -- [ -f "$DEST_DIR/gogo" ]; then
    lxc exec "$LXC_HOSTNAME" -- mkdir -p "$DEST_DIR"
    lxc exec "$LXC_HOSTNAME" -- touch "$DEST_DIR/gogo"
fi