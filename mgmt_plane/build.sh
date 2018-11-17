#!/bin/bash

set -eu
cd "$(dirname "$0")"

if [[ -z $(docker image list | grep "bcm-trezor") ]]; then
    docker build -t bcm-trezor:latest .
else
    # make sure the container is up-to-date, but don't display
    echo "Updating docker image bcm-trezor:latest ..."
    docker build -t bcm-trezor:latest . >> /dev/null
fi


#docker pull ipfs/go-ipfs
