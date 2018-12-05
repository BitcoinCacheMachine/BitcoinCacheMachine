#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

if ! docker image list | grep -q "bcm-trezor"; then
    # make sure the container is up-to-date, but don't display
    echo "Updating docker image bcm-trezor:latest ..."
    docker build -t bcm-trezor:latest .
fi

docker build -t bcm-trezor:latest .

# build the image that has 'pass' on it.
if ! docker image list | grep -q "bcm-pass"; then
    docker build -t bcm-pass:latest ./pass/
else
    # make sure the container is up-to-date, but don't display
    echo "Updating docker image bcm-pass:latest ..."
    docker build -t bcm-pass:latest ./pass/
fi
