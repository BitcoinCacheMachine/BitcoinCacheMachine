#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! docker image list | grep -q "bcm-trezor"; then
    docker build -t bcm-trezor:latest .
else
    # make sure the container is up-to-date, but don't display
    echo "Updating docker image bcm-trezor:latest ..."
    docker build -t bcm-trezor:latest .
fi

# build the image that has 'pass' on it.
if ! docker image list | grep -q "bcm-pass"; then
    docker build -t bcm-pass:latest ./pass/
else
    # make sure the container is up-to-date, but don't display
    echo "Updating docker image bcm-pass:latest ..."
    docker build -t bcm-pass:latest ./pass/
fi
