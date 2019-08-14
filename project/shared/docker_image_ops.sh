#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

LXC_HOST=
DOCKER_HUB_IMAGE=
IMAGE_NAME=
BUILD_CONTEXT=

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

# if DOCKER_HUB_IMAGE was passed, we assume that we are simply downloading it and pushing it to our private registry.
# no operations will be performed otherwise.
if [[ ! -z $DOCKER_HUB_IMAGE ]]; then
    lxc exec "$LXC_HOST" -- docker pull "$DOCKER_HUB_IMAGE"
    
    FULLY_QUALIFIED_IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"
    lxc exec "$LXC_HOST" -- docker tag "$DOCKER_HUB_IMAGE" "$FULLY_QUALIFIED_IMAGE_NAME"
    lxc exec "$LXC_HOST" -- docker push "$FULLY_QUALIFIED_IMAGE_NAME"
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

function docker_tag_exists() {
    lxc exec "$BCM_MANAGER_HOST_NAME" -- curl -s -f -lSL "http://127.0.0.1:5010/v2/$1/tags/list" | grep "$1" | grep "$2"
}

REBUILD=1
if [[ $REBUILD == 1 ]]; then
    # let's make sure there's a dockerfile
    if [[ ! -f "$BUILD_CONTEXT/Dockerfile" ]]; then
        echo "There was no Dockerfile found in the build context."
        exit
    else
        echo "Pushing contents of the build context to LXC host '$LXC_HOST'."
        lxc file push -r -p "$BUILD_CONTEXT/" "$LXC_HOST/root"
    fi
    
    # refresh the docker-base image
    bash -c "$BCM_GIT_DIR/project/tiers/manager/build_push_docker_base.sh"
    
    # let's build the image and push it to our private registry.
    IMAGE_FQDN="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"
    
    echo "Preparing the docker image '$IMAGE_FQDN'"
    lxc exec "$LXC_HOST" -- docker build --build-arg BCM_PRIVATE_REGISTRY="$BCM_PRIVATE_REGISTRY" --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" -t "$IMAGE_FQDN" /root/build/
    lxc exec "$LXC_HOST" -- docker push "$IMAGE_FQDN"
else
    echo "The image already exists in the private registry. It will not be re-built."
fi
