#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#bcm stack start bitcoind

# source the bitcoind information so we can pass it to the stack.
# shellcheck source=../bitcoind/env.sh
source "$BCM_STACKS_DIR/bitcoind/env.sh"

# override anything from bitcoind/env.sh
source ./env.sh

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
# shellcheck source=../../project/shared/env.sh
source "$BCM_GIT_DIR/project/shared/env.sh"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"
IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$IMAGE_NAME" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
CHAIN_TEXT="$CHAIN_TEXT" \
TOR_SOCKS5_PROXY_HOSTNAME="$BCM_MANAGER_HOST_NAME" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"

# wait for the REST API to come online.
#lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker run --rm "$IMAGE_NAME" --network "lnd-$BCM_ACTIVE_CHAIN""_lndrpcnet" wait-for-it -t 30 "lndrpc-$BCM_ACTIVE_CHAIN:8080"
sleep 20

# check for the wallet.db file; if it doesn't exist, then we run lncli create
if lxc exec "$BCM_BITCOIN_HOST_NAME" -- [ ! -d "/var/lib/docker/volumes/lnd-$BCM_ACTIVE_CHAIN""_data/_data/data/chain" ]; then
    bcm lncli create
else
    echo "Info: existing lnd wallet exists."
fi
