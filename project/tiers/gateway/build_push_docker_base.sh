#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/cli/env"

# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
lxc exec bcm-gateway-01 -- docker pull ubuntu:18.04

lxc file push -p -r ./build/ bcm-gateway-01/root/gateway/

lxc exec bcm-gateway-01 -- BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" docker build -t "$BCM_PRIVATE_REGISTRY/bcm-docker-base:$BCM_DOCKER_BASE_TAG" /root/gateway/build/
lxc exec bcm-gateway-01 -- docker push "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest"
