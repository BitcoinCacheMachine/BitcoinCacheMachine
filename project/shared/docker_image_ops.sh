#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/env"

LXC_HOST=
DOCKER_HUB_IMAGE=
IMAGE_NAME=
IMAGE_TAG=latest
BUILD_CONTEXT=
IMAGE_TAGGED_FLAG=0
IMAGE_EXISTS=0
PRIVATE_REGISTRY="$BCM_PRIVATE_REGISTRY"

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
        --registry=*)
            PRIVATE_REGISTY="${i#*=}"
            shift # past argument=value
        ;;
        --image-name=*)
            IMAGE_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --image-tag=*)
            IMAGE_TAG="${i#*=}"
            shift # past argument=value
        ;;
        --build-context=*)
            BUILD_CONTEXT="${i#*=}"
            shift # past argument=value
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

if [[ -z $PRIVATE_REGISTRY ]]; then
    echo "PRIVATE_REGISTRY is empty. Exiting"
    exit
fi

if [[ ! -z $BUILD_CONTEXT ]]; then
    if [[ ! -d $BUILD_CONTEXT ]]; then
        echo "The build context was not passed properly."
        exit
    fi
else
    echo "The build context was empty."
    exit
fi

if ! lxc list --format csv -c n | grep -q "$LXC_HOST"; then
    echo "LXC host '$LXC_HOST' doesn't exist. Exiting"
    exit
fi

# if DOCKER_HUB_IMAGE was passed, we assume that we are simply downloading it and pushing it to our private registry.
# no operations will be performed otherwise.
if [[ ! -z $DOCKER_HUB_IMAGE ]]; then
    lxc exec "$LXC_HOST" -- docker pull "$DOCKER_HUB_IMAGE"
    lxc exec "$LXC_HOST" -- docker tag "$DOCKER_HUB_IMAGE" "$PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    lxc exec "$LXC_HOST" -- docker push "$PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    exit
fi

# if the user has asked us to build an image, we will do so
#lxc exec bcm-gateway-01 -- curl http://127.0.0.1:5010/v2/bcm-bitcoin-core/manifests/17.1


# first, we check to see if the image already exists in our private registry. If it does, we won't do anything.
if [[ $IMAGE_EXISTS == 0 ]]; then
    # let's make sure there's a dockerfile
    if [[ ! -f "$BUILD_CONTEXT/Dockerfile" ]]; then
        echo "There was no Dockerfile found in the build context."
        exit
    else
        echo "Pushing contents of the build context to LXC host '$LXC_HOST'."
        lxc file push -r -p "$BUILD_CONTEXT/" "$LXC_HOST/root"
    fi
    
    # let's build the image and push it to our private registry.
    lxc exec "$LXC_HOST" -- docker build -t "$PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" /root/build/
    lxc exec "$LXC_HOST" -- docker push "$PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
else
    echo "The image already exists in the private registry. It will not be re-built."
fi
