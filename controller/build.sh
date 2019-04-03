#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# in case we're running this script outside of the bcm context
source "$BCM_GIT_DIR/cli/env"

if ! docker images -q "bcm-trezor"; then
    docker image rm --force $(docker images -q "bcm-trezor")
fi
# if there's an issue resolving archive.ubuntu.com, follow these steps:
#https://development.robinwinslow.uk/2016/06/23/fix-docker-networking-dns/#the-permanent-system-wide-fix

docker build --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" -t "bcm-trezor:$BCM_VERSION" .
docker build --build-arg BCM_VERSION="$BCM_VERSION" -t "bcm-gpgagent:$BCM_VERSION" ./gpgagent/
