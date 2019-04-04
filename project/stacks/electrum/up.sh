#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

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

#  TODO make MACVLAN interface accessible somehow...
#sudo route add -4 "$(bcm get-ip)"/32 dev wlp3s0 metric 50
mkdir -p "$ELECTRUM_DIR/testnet"
mkdir -p "$ELECTRUM_DIR/regtest"

cp ./config "$ELECTRUM_DIR/testnet/config"
cp ./config "$ELECTRUM_DIR/config"

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

docker run -it --rm --net=host \
-e DISPLAY="$DISPLAY" \
-e XAUTHORITY=${XAUTH} \
-e CHAIN="$(bcm get-chain)" \
-e ENDPOINT="$(bcm get-ip)" \
-v "$XSOCK":"$XSOCK":rw \
-v "$XAUTH":"$XAUTH":rw \
-v "$ELECTRUM_DIR":/home/user/.electrum \
--privileged \
bcm-electrum:3.3.4
