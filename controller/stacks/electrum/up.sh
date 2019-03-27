#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

echo "up.sh for electrum wallet."

if ! bcm stack list | grep -q "electrs"; then
    bcm stack deploy electrs
fi

IMAGE_NAME=bcm-electrum:3.3.4

if ! docker images --format '{{ .Repository }}:{{ .Tag }}' | grep -q "$IMAGE_NAME"; then
    docker build -t "$IMAGE_NAME" ./build/
fi

#  TODO make MACVLAN interface accessible somehow...
#sudo route add -4 "$(bcm get-ip)"/32 dev wlp3s0 metric 50

ELECTRUM_DIR="$BCM_RUNTIME_DIR/electrum"
mkdir -p "$ELECTRUM_DIR"

docker run -it --rm --net=host -e DISPLAY="$DISPLAY" -e CHAIN="$BCM_DEFAULT_CHAIN" -e ENDPOINT="$(bcm get-ip)" -v /tmp/.X11-unix:/tmp/.X11-unix -v "$ELECTRUM_DIR":/home/user/.electrum --privileged bcm-electrum:3.3.4
