#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# push the stack files up tthere.
lxc file push  -p -r ./build/ "$BCM_BITCOIN_HOST_NAME"/root/torproxy

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:$BCM_VERSION"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker build \
--build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" \
--build-arg BCM_PRIVATE_REGISTRY="$BCM_PRIVATE_REGISTRY" \
-t "$TOR_IMAGE" "/root/torproxy/build"

lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker push "$TOR_IMAGE"

# push the stack files up tthere.
lxc file push  -p -r ./stack/ "$BCM_MANAGER_HOST_NAME"/root/toronion

lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker pull "$TOR_IMAGE"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c "/root/toronion/stack/toronion.yml" "toronion"

sleep 10

# now we wait for the service to start, then we grab the new onion site and token
# then we add it to our config using bcm ssh add-onion
DOCKER_CONTAINER_ID=$(lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker ps | grep toronion | awk '{print $1}')
if [[ ! -z $DOCKER_CONTAINER_ID ]]; then
    ONION_CREDENTIALS="$(lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker exec -t "$DOCKER_CONTAINER_ID" cat /var/lib/tor/bcmonion/hostname)"
    
    if [[ ! -z $ONION_CREDENTIALS ]]; then
        ONION_URL="$(echo "$ONION_CREDENTIALS" | awk '{print $1;}')"
        ONION_TOKEN="$(echo "$ONION_CREDENTIALS" | awk '{print $2;}')"
        bcm ssh add-onion --onion="$ONION_URL" --token="$ONION_TOKEN" --title="$(lxc remote get-default)"
    fi
else
    echo "WARNING: Docker container not found for 'toronion'. You may need to run 'bcm stack start toronion'."
fi
