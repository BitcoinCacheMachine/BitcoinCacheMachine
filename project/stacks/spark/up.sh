#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env

# first, let's make sure we deploy our direct dependencies.
bcm stack deploy clightning

# this is the LXC host that the docker container is going to be provisioned to.
HOST_ENDING="01"
CONTAINER_NAME="bcm-$TIER_NAME-$HOST_ENDING"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$CONTAINER_NAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$BCM_DEFAULT_CHAIN" \
HOST_ENDING="$HOST_ENDING" \
SERVICE_PORT="$BCM_SERVICE_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$BCM_DEFAULT_CHAIN"

ENDPOINT=$(bcm get-ip)
wait-for-it -t 0 "$ENDPOINT:$SERVICE_PORT"
xdg-open http://"$ENDPOINT:$SERVICE_PORT" &