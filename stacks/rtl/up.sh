#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env.sh

bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=lnd"

# prepare the image.
"$BCM_LXD_OPS/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

RTL_PASS="Password1"
ENDPOINT=$(bcm get-ip)


lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
SERVICE_PORT="$SERVICE_PORT" \
RTL_PASS="$RTL_PASS" \
REDIRECT_LINK="http://$ENDPOINT:$SERVICE_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"

wait-for-it -t 0 "$ENDPOINT:$SERVICE_PORT"

# # let's the the pariing URL from the container output
# PAIRING_OUTPUT_URL=$(lxc exec "$BCM_MANAGER_HOST_NAME" -- docker service logs "$STACK_NAME-$BCM_ACTIVE_CHAIN""_$SERVICE_NAME" | grep 'Pairing URL: ' | awk '{print $5}')
# RTL_URL=${PAIRING_OUTPUT_URL/0.0.0.0/$ENDPOINT}

xdg-open "http://$ENDPOINT:$SERVICE_PORT"
