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

# first, let's make sure we deploy our direct dependencies.
bcm stack deploy bitcoind --chain="$CHAIN"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name=bcm-bitcoin-01 \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "bcm-gateway-01/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec bcm-gateway-01 -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" CHAIN="$CHAIN" HOST_ENDING="01" docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$CHAIN"

DEST_DIR="/var/lib/docker/volumes/clightning-""$CHAIN""_clightning-data/_data"
lxc exec bcm-bitcoin-01 -- touch "$DEST_DIR/gogo"