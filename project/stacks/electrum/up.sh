#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# This stack run as a desktop GUI application on the SDN Controller. As such, it runs directly in
# dockerd and not expected to be within an LXC context.
if ! bcm stack list | grep -q "electrs"; then
    bcm stack deploy electrs
fi

# Using Electrum Wallet 3.3.4
IMAGE_NAME="bcm-electrum:$BCM_VERSION"

bash -c "$BCM_GIT_DIR/controller/build.sh"

docker build -t "$IMAGE_NAME" --build-arg BCM_VERSION="$BCM_VERSION" ./build/

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


# let's check on our back end services.
BACK_END_IP=$(bcm get-ip)
source "$BCM_GIT_DIR/project/stacks/electrs/env"

wait-for-it -t 0 "$BACK_END_IP:$ELECTRS_RPC_PORT"

ELECTRUM_CMD_TXT=""
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    ELECTRUM_CMD_TXT="--testnet"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    ELECTRUM_CMD_TXT="--regtest"
fi

# todo review permissions on this app running.
docker run -it --rm --net=host \
-e DISPLAY="$DISPLAY" \
-e XAUTHORITY="${XAUTH}" \
-e BACK_END_IP="$BACK_END_IP" \
-e ELECTRS_RPC_PORT="$ELECTRS_RPC_PORT" \
-e ELECTRUM_CMD_TXT="$ELECTRUM_CMD_TXT" \
-v "$XSOCK":"$XSOCK":rw \
-v "$XAUTH":"$XAUTH":rw \
-v "$ELECTRUM_DIR":/home/user/.electrum \
--privileged \
"$IMAGE_NAME"
