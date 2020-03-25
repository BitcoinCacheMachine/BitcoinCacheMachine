#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

IMAGE_TITLE=
BASE_IMAGE=

for i in "$@"; do
    case $i in
        --image-title=*)
            IMAGE_TITLE="${i#*=}"
            shift # past argument=value
        ;;
        --base-image=*)
            BASE_IMAGE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z "$IMAGE_TITLE" ]]; then
    echo "ERROR: IMAGE_TITLE not set."
    exit -1
fi

if [[ -z "$BASE_IMAGE" ]]; then
    echo "ERROR: BASE_IMAGE not set."
    exit -1
fi

# pull the base image
if [[ -z "$(docker images -q "$BASE_DOCKER_IMAGE")" ]]; then
    docker image pull "$BASE_DOCKER_IMAGE"
fi

IMAGE_FQDN="bcm-$IMAGE_TITLE:$BCM_VERSION"
if [ -z "$(docker images -q "$IMAGE_FQDN")" ] || [ "$REBUILD_IMAGES" == 1 ]; then
    docker build --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$IMAGE_FQDN" "$BCM_COMMAND_DIR/controller/$IMAGE_TITLE/"
fi