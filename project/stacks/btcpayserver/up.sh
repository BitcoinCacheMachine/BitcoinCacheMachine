#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env

# first, let's make sure we deploy our direct dependencies.
bcm stack deploy nbxplorer
#bcm stack deploy lightning-charge

# this is the LXC host that the docker container is going to be provisioned to.
HOST_ENDING="01"
CONTAINER_NAME="bcm-bitcoin-$HOST_ENDING"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--docker-hub-image-name="$DOCKER_HUB_IMAGE" \
--container-name="$CONTAINER_NAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "bcm-gateway-01/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec bcm-gateway-01 -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$BCM_DEFAULT_CHAIN" \
HOST_ENDING="$HOST_ENDING" \
SERVICE_PORT="$SERVICE_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$BCM_DEFAULT_CHAIN"
