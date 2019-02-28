#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env

CHAIN=

for i in "$@"; do
    case $i in
        --chain=*)
            CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $CHAIN ]]; then
    echo "CHAIN not specified. Exiting"
    exit
fi

# Perform provisioning activities for dependent dier.
bash -c "$BCM_GIT_DIR/project/tiers/ui/up.sh"

# this is the LXC host that the docker container is going to be provisioned to.
HOST_ENDING="01"
CONTAINER_NAME="bcm-bitcoin-$HOST_ENDING"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build/" \
--container-name="$CONTAINER_NAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$BCM_STACKS_DIR/bitcoind/" "bcm-gateway-01/root/stacks/bitcoin/"

#AUTH_PASSWORD="$(apg -n 1 -m 30 -M CN)"
#AUTH_PASSWORD_HASH=$(python3 rpcauth.py bitcoind "$AUTH_PASSWORD" | grep "rpcauth=")

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" CHAIN="$CHAIN" HOST_ENDING="$HOST_ENDING" docker stack deploy -c "/root/stacks/bitcoin/bitcoind/$STACK_FILE" "$STACK_NAME-$CHAIN"

UPLOAD_BLOCKS=0
UPLOAD_CHAINSTATE=0

SRC_DIR="$HOME/.bitcoin"
DEST_DIR='/var/lib/docker/volumes/bitcoind-'"$CHAIN"'_bitcoin_data/_data'
if [[ $CHAIN == "testnet" ]]; then
    SRC_DIR="$HOME/.bitcoin/testnet3"
    DEST_DIR="$DEST_DIR/testnet3"
fi

# if the $HOME/.bitcoin/blocks (or testnet3/blocks) directory exists,
# then we can use it to seed # our new full node with blocks.
# this is better because we won't have to bog the TOR network down.
if [[ -d "$SRC_DIR/blocks" ]]; then
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
    if ! lxc exec "$CONTAINER_NAME" -- [ -f "$DEST_DIR/gogo" ]; then
        lxc file push -r -p "$SRC_DIR/blocks" "$CONTAINER_NAME/$DEST_DIR"
    else
        echo "INFO: Skipping upload of blocks since it appears to have been uploaded already."
    fi
fi

if [[ "$UPLOAD_CHAINSTATE" == 1 ]]; then
    if ! lxc exec "$CONTAINER_NAME" -- [ -f "$DEST_DIR/gogo" ]; then
        lxc file push -r -p "$SRC_DIR/chainstate" "$CONTAINER_NAME/$DEST_DIR"
    else
        echo "INFO: Skipping upload of chainstate since it appears to have been uploaded already."
    fi
fi

if ! lxc exec "$CONTAINER_NAME" -- [ -f "$DEST_DIR/gogo" ]; then
    lxc exec "$CONTAINER_NAME" -- mkdir -p "$DEST_DIR"
    lxc exec "$CONTAINER_NAME" -- touch "$DEST_DIR/gogo"
fi