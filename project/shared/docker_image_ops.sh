#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

LXC_HOST=
DOCKER_HUB_IMAGE=
IMAGE_NAME=
BUILD_CONTEXT=
REBUILD=0

for i in "$@"; do
    case $i in
        --container-name=*)
            LXC_HOST="${i#*=}"
            shift # past argument=value
        ;;
        --docker-hub-image-name=*)
            DOCKER_HUB_IMAGE="${i#*=}"
            shift # past argument=value
        ;;
        --image-name=*)
            IMAGE_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --build-context=*)
            BUILD_CONTEXT="${i#*=}"
            shift # past argument=value
        ;;
        --rebuild)
            REBUILD=1
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $LXC_HOST ]]; then
    echo "LXC_HOST is empty. Exiting"
    exit
fi

if [[ -z $IMAGE_NAME ]]; then
    echo "IMAGE_NAME is empty. Exiting"
    exit
fi

if [[ -z $BCM_PRIVATE_REGISTRY ]]; then
    echo "BCM_PRIVATE_REGISTRY is empty. Exiting"
    exit
fi

if ! lxc list --format csv -c n | grep -q "$LXC_HOST"; then
    echo "LXC host '$LXC_HOST' doesn't exist. Exiting"
    exit
fi

# let's first check to see if the image is in the local registry for private images
# if so, we can just pull that down and exit.
FULLY_QUALIFIED_IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"

# if the build context is empty, then we should probably pull from dockerhub.
if [[ -z $BUILD_CONTEXT ]]; then
    
    # before we pull from dockerhub, let's check to see if it's in our local registry already
    IMAGE_EXISTS_IN_DOCKER_REG="$(lxc exec $LXC_HOST -- docker image pull "$FULLY_QUALIFIED_IMAGE_NAME" > /dev/null && echo 1 || echo 0)"
    if [[ $IMAGE_EXISTS_IN_DOCKER_REG == 0 ]]; then
        if [[ -z $DOCKER_HUB_IMAGE ]]; then
            echo "ERROR: DOCKER_HUB_IMAGE not set."
            exit
        fi
        
        # if the image doesn't exist in our docker registry, and not in our local docker daemon either
        # then we can pull it down from the public Docker registry and tag and push it appropriately.
        if ! lxc exec "$LXC_HOST" -- docker image list | grep -q "$DOCKER_HUB_IMAGE"; then
            lxc exec "$LXC_HOST" -- docker image pull "$DOCKER_HUB_IMAGE"
            lxc exec "$LXC_HOST" -- docker tag "$DOCKER_HUB_IMAGE" "$FULLY_QUALIFIED_IMAGE_NAME"
            lxc exec "$LXC_HOST" -- docker push "$FULLY_QUALIFIED_IMAGE_NAME"
        fi
    else
        echo "INFO: the image '$FULLY_QUALIFIED_IMAGE_NAME' was found in the BCM local docker registry."
    fi
else
    # let's make sure there's a dockerfile
    if [[ -f "$BUILD_CONTEXT/Dockerfile" ]]; then
        echo "Pushing contents of the build context to LXC host '$LXC_HOST'."
        lxc file push -r -p "$BUILD_CONTEXT/" "$LXC_HOST/root"
        
        echo "Building the docker image '$FULLY_QUALIFIED_IMAGE_NAME'"
        FULLY_QUALIFIED_BASE_IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$BASE_IMAGE:$BCM_VERSION"
        lxc exec "$LXC_HOST" -- docker pull "$FULLY_QUALIFIED_BASE_IMAGE_NAME"
        lxc exec "$LXC_HOST" -- docker build --build-arg BASE_IMAGE="$FULLY_QUALIFIED_BASE_IMAGE_NAME" -t "$FULLY_QUALIFIED_IMAGE_NAME" /root/build/
        lxc exec "$LXC_HOST" -- docker push "$FULLY_QUALIFIED_IMAGE_NAME"
    fi
fi
