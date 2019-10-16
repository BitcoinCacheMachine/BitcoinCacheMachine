#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

IMAGE_NAME="$BCM_PRIVATE_REGISTRY/bcm-tor:$BCM_VERSION"
bash -c "$BCM_LXD_OPS/docker_image_ops.sh --build-context=$STACK_FILE_DIRNAME/build --container-name=$BCM_BITCOIN_HOST_NAME --image-name=$IMAGE_NAME"


# # push the stack files up tthere.
# lxc file push  -p -r ./build/ "$BCM_BITCOIN_HOST_NAME"/root/torproxy


# lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker build --build-arg BASE_IMAGE="$" -t "$TOR_IMAGE" "/root/torproxy/build"
# lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker push "$TOR_IMAGE"

# push the stack files up tthere.
lxc file push  -p -r ./stack/ "$BCM_MANAGER_HOST_NAME"/root/toronion

lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker image pull "$TOR_IMAGE"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c "/root/toronion/stack/toronion.yml" "toronion"
