#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

source ./env

# this stores cached jekyll data that is pulled from the
# internet the first time an image is created.
if ! docker volume list | grep -q "$BUILDCACHE_DOCKERVOL"; then
    docker volume create "$BUILDCACHE_DOCKERVOL"
fi

if docker image list | grep -q "$BCM_DOCKER_BASE_TAG"; then
    docker image pull "$BCM_DOCKER_BASE_TAG"
fi

docker tag "$BCM_DOCKER_BASE_TAG" "jekyll:$SITE_NAME"

docker run --rm -it \
-v "$BUILDCACHE_DOCKERVOL":/usr/local/bundle \
-v "$SITE_PATH:/srv/jekyll" \
"jekyll:$SITE_NAME" jekyll build --trace
