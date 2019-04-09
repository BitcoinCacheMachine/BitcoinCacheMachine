#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
lxc exec "$LXC_HOSTNAME" -- docker pull "ubuntu:$BCM_DOCKER_BASE_TAG"

lxc file push -p -r ./build/ "$LXC_HOSTNAME"/root/gateway/

IMAGE_NAME="$BCM_PRIVATE_REGISTRY/bcm-docker-base:$BCM_DOCKER_BASE_TAG"

lxc exec "$LXC_HOSTNAME" -- docker build --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" -t "$IMAGE_NAME" /root/gateway/build/
lxc exec "$LXC_HOSTNAME" -- docker push "$IMAGE_NAME"
