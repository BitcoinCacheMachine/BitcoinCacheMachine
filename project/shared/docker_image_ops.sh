#!/bin/bash

set -Eeuo pipefail
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


FULLY_QUALIFIED_IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"

# let's first check to see if the image is in the local registry for private images
# if so, we can just pull that down and exit.
if [[ $REBUILD == 0 ]]; then
    FETCH_STATUS="$(lxc exec $LXC_HOST -- docker image pull "$FULLY_QUALIFIED_IMAGE_NAME" > /dev/null && echo 1 || echo 0)"
    if [[ $FETCH_STATUS == 1 ]]; then
        echo "sucess"
    else
        echo "not success"
    fi
    
    exit
fi

# first we ensure out original public image is available.
if lxc exec "$LXC_HOST" -- docker image list | grep -q "$DOCKER_HUB_IMAGE"; then
    lxc exec "$LXC_HOST" -- docker image pull "$DOCKER_HUB_IMAGE"
fi

# then we tag it as being for bcm.
if lxc exec "$LXC_HOST" -- docker image list | grep -q "$FULLY_QUALIFIED_IMAGE_NAME"; then
    lxc exec "$LXC_HOST" -- docker tag "$DOCKER_HUB_IMAGE" "$FULLY_QUALIFIED_IMAGE_NAME"
fi

lxc exec "$LXC_HOST" -- docker push "$FULLY_QUALIFIED_IMAGE_NAME"

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
    
    # let's build the image and push it to our private registry.
    IMAGE_FQDN="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"
    
    echo "Preparing the docker image '$IMAGE_FQDN'"
    lxc exec "$LXC_HOST" -- docker build --build-arg BCM_PRIVATE_REGISTRY="$BCM_PRIVATE_REGISTRY" --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$IMAGE_FQDN" /root/build/
    lxc exec "$LXC_HOST" -- docker push "$IMAGE_FQDN"
else
    echo "The image already exists in the private registry. It will not be re-built."
fi
