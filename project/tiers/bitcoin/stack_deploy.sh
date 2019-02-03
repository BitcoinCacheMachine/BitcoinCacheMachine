#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/env"

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

# get the env from bitcoind
source "$(pwd)/stacks/bitcoind/env"
STACK_FILE_DIRNAME="$(pwd)/stacks/bitcoind"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$STACK_FILE_DIRNAME/build" \
--container-name=bcm-bitcoin-01 \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$STACK_FILE_DIRNAME/" "bcm-gateway-01/root/stacks/bitcoin/"

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" CHAIN="$CHAIN" docker stack deploy -c "/root/stacks/bitcoin/bitcoind/$STACK_FILE" "$STACK_NAME-$CHAIN"
