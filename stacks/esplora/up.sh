#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env.sh

# first, let's make sure we deploy our direct dependencies.
if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep -q "$STACK_NAME" | grep -q "bitcoind"; then
    bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=bitcoind"
fi

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$CONTAINER_NAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

# shellcheck source=..bitcoind/env.sh
source "$BCM_STACKS_DIR/bitcoind/env"
source ./env

lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
BITCOIND_RPC_PORT="$BITCOIND_RPC_PORT" \

docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"



ENDPOINT=$(bcm get-ip)
wait-for-it -t 0 "$ENDPOINT:$SERVICE_PORT"
xdg-open http://"$ENDPOINT:$SERVICE_PORT" &
