#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! bcm stack list | grep -q "electrs"; then
    bcm stack deploy electrs
fi

IMAGE_NAME=bcm-electrum:3.3.4

if ! docker images --format '{{ .Repository }}:{{ .Tag }}' | grep -q "$IMAGE_NAME"; then
    # call the controller build script for the base image just to ensure it exists
    bash -c "$BCM_GIT_DIR/controller/build.sh"
    
    docker build -t "$IMAGE_NAME" --build-arg BCM_VERSION="$BCM_VERSION" ./build/
fi

#  TODO make MACVLAN interface accessible somehow...
#sudo route add -4 "$(bcm get-ip)"/32 dev wlp3s0 metric 50
if [[ ! -d "$ELECTRUM_DIR" ]]; then
    mkdir "$ELECTRUM_DIR/testnet"
fi

cp ./config "$ELECTRUM_DIR/testnet/config"
cp ./config "$ELECTRUM_DIR/config"

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

docker run -it --rm --net=host \
-e DISPLAY="$DISPLAY" \
-e XAUTHORITY=${XAUTH} \
-e CHAIN="$BCM_DEFAULT_CHAIN" \
-e ENDPOINT="$(bcm get-ip)" \
-v $XSOCK:$XSOCK:rw \
-v $XAUTH:$XAUTH:rw \
-v "$ELECTRUM_DIR":/home/user/.electrum \
--privileged \
bcm-electrum:3.3.4
