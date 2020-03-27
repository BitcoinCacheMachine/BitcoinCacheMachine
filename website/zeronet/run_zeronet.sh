#!/bin/bash

set -Eeox pipefail
cd "$(dirname "$0")"

IMAGE_NAME="nofish/zeronet"


# for dir in data logs plugins; do
#     docker volume create $dir

# done
ZERONET_DIR="$HOME/zeronet"
DATA_DIR="$ZERONET_DIR/data"
LOG_DIR="$ZERONET_DIR/logs"
PLUGINS_DIR="$ZERONET_DIR/plugins"
TOR_DIR="$ZERONET_DIR/tor"

docker pull "$IMAGE_NAME"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$PLUGINS_DIR"
mkdir -p "$TOR_DIR"

docker run --name zeronet -d \
-e ENABLE_TOR=true \
-v "$DATA_DIR":/root/data  \
-v "$LOG_DIR":/root/log \
-p 127.0.0.1:43110:43110/tcp \
"$IMAGE_NAME"

#-v "$ZERONET_TOR_DIR":/root/.tor
#-v "$ZERONET_PLUGINS_DIR":/root/plugins

wait-for-it -t 10 "127.0.0.1:43110"

# let's the the pariing URL from the container output
sleep 5

xdg-open "http://127.0.0.1:43110"
