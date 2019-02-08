#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
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

# get the env
source ./env

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name=bcm-bitcoin-01 \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "bcm-gateway-01/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec bcm-gateway-01 -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" CHAIN="$CHAIN" HOST_ENDING="01" docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$CHAIN"
