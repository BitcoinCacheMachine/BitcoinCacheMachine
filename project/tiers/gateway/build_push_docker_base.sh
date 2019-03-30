#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/cli/env"

# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker pull ubuntu:18.04

lxc file push -p -r ./build/ "$BCM_GATEWAY_HOST_NAME"/root/gateway/

lxc exec "$BCM_GATEWAY_HOST_NAME" -- BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" docker build -t "$BCM_PRIVATE_REGISTRY/bcm-docker-base:$BCM_DOCKER_BASE_TAG" /root/gateway/build/
lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker push "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest"
