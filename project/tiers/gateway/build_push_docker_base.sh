#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/cli/env"

# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker pull "ubuntu:$BCM_DOCKER_BASE_TAG"

lxc file push -p -r ./build/ "$BCM_GATEWAY_HOST_NAME"/root/gateway/

IMAGE_NAME="$BCM_PRIVATE_REGISTRY/bcm-docker-base:$BCM_DOCKER_BASE_TAG"

lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker build --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" -t "$IMAGE_NAME" /root/gateway/build/
lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker push "$IMAGE_NAME"
