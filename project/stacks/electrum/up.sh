#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/project/stacks/electrs/env.sh"

# This stack run as a desktop GUI application on the SDN Controller. As such, it runs directly in
# dockerd and not expected to be within an LXC context.
if ! bcm stack list | grep -q "electrs"; then
    bcm stack deploy electrs
fi

# Using Electrum Wallet 3.3.4
IMAGE_NAME="bcm-electrum:$BCM_VERSION"

if ! docker images --format '{{ .Repository }}:{{ .Tag }}' | grep -q "$IMAGE_NAME"; then
    # call the controller build script for the base image just to ensure it exists
    bash -c "$BCM_GIT_DIR/controller/build.sh"
    
    docker build -t "$IMAGE_NAME" --build-arg BCM_VERSION="$BCM_VERSION" ./build/
fi


# let's check on our back end services.
BACK_END_IP=$(bcm get-ip)
CHAIN=$BCM_ACTIVE_CHAIN

mkdir -p "$ELECTRUM_DIR"
mkdir -p "$ELECTRUM_DIR/regtest"
mkdir -p "$ELECTRUM_DIR/testnet"
cp ./regtest_config.json "$ELECTRUM_DIR/regtest/config"
cp ./testnet_config.json "$ELECTRUM_DIR/testnet/config"
cp ./mainnet_config.json "$ELECTRUM_DIR/config"

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -


docker run -it --rm --net=host \
-e DISPLAY="$DISPLAY" \
-e XAUTHORITY="${XAUTH}" \
-e CHAIN="$CHAIN" \
-e ENDPOINT="$BACK_END_IP" \
-e CHAIN_TEXT="$CHAIN_TEXT" \
-e SERVICE_PORT="$SERVICE_PORT" \
-v "$XSOCK":"$XSOCK":rw \
-v "$XAUTH":"$XAUTH":rw \
-v "$ELECTRUM_DIR":/home/user/.electrum \
--privileged \
"$IMAGE_NAME"
