#!/bin/bash

set -Eeuo pipefail
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

if [[ -z $CHAIN ]]; then
    echo "CHAIN not specified. Exiting"
    exit
fi

# this is the LXC host that the docker container is going to be provisioned to.
HOST_ENDING="01"

# get the env from bitcoind
source "$(pwd)/bitcoind/env"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/bitcoind/build" \
--container-name="bcm-bitcoin-$HOST_ENDING" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/bitcoind/" "bcm-gateway-01/root/stacks/bitcoin/"

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" CHAIN="$CHAIN" HOST_ENDING="$HOST_ENDING" docker stack deploy -c "/root/stacks/bitcoin/bitcoind/$STACK_FILE" "$STACK_NAME-$CHAIN"
