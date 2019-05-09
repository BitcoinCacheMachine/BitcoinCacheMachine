#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! bcm stack list | grep -q bitcoind; then
    # first, let's make sure we deploy our direct dependencies.
    bcm stack start bitcoind
fi

echo "WARNING: lnd deployment using BCM has NOT been fully automated. You MUST be prepared"
echo "         to generate and store unique passwords and cipher seeds."


# source the bitcoind information so we can pass it to the stack.
source "$BCM_STACKS_DIR/bitcoind/env.sh"

# override anything from bitcoind/env.sh
source ./env.sh

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
source "$BCM_GIT_DIR/project/shared/env.sh"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
CHAIN_TEXT="$CHAIN_TEXT" \
TOR_SOCKS5_PROXY_HOSTNAME="$BCM_GATEWAY_HOST_NAME" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"
