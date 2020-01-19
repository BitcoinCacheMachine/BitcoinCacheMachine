#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env

bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=clightning"
bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=nbxplorer"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--docker-hub-image-name="$DOCKER_HUB_IMAGE" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
SERVICE_PORT="$SERVICE_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"

ENDPOINT=$(bcm get-ip)
wait-for-it -t 0 "$ENDPOINT:$SERVICE_PORT"
xdg-open http://"$ENDPOINT:$SERVICE_PORT" &