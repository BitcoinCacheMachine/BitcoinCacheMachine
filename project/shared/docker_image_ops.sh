#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

LXC_HOST=
DOCKER_HUB_IMAGE=
BCM_IMAGE_NAME=
BCM_HELP_FLAG=0
BUILD_CONTEXT=
PUSH_DEST_REGISTRY=
IMAGE_TAGGED_FLAG=0

for i in "$@"
do
case $i in
    --container-name=*)
    LXC_HOST="${i#*=}"
    shift # past argument=value
    ;;
    --image-name=*)
    DOCKER_HUB_IMAGE="${i#*=}"
    shift # past argument=value
    ;;
    --registry=*)
    PUSH_DEST_REGISTRY="${i#*=}"
    shift # past argument=value
    ;;
    --priv-image-name=*)
    BCM_IMAGE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --build)
    BCM_HELP_FLAG=1
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

if [[ -z $BCM_IMAGE_NAME ]]; then
    echo "BCM_IMAGE_NAME is empty. Exiting"
    exit
fi

# if a registry has been passed, let's ensure the image name properly reflects
# otherwise this script assumes that the user has properly namespaced the image name
if [[ ! -z $PUSH_DEST_REGISTRY ]]; then
    BCM_IMAGE_NAME="$PUSH_DEST_REGISTRY/$BCM_IMAGE_NAME"
fi 

if ! lxc list --format csv -c n | grep -q "$LXC_HOST"; then
    echo "LXC host '$LXC_HOST' doesn't exist. Exiting"
    exit
fi

if [[ ! -z $DOCKER_HUB_IMAGE ]]; then
    lxc exec "$LXC_HOST" -- docker pull "$DOCKER_HUB_IMAGE"
fi

# if the user has asked us to build an image, we will do so
if [[ $BCM_HELP_FLAG = 1 ]]; then
    # make sure they have passed a build context directory.
    if [[ -d $BUILD_CONTEXT ]]; then
        # let's make sure there's a dockerfile
        if [[ ! -f "$BUILD_CONTEXT/Dockerfile" ]]; then
            echo "There was no Dockerfile found in the build context."
            exit
        fi

        if [[ ! -z $BCM_IMAGE_NAME ]]; then
            echo "Pushing contents of the build context to LXC host '$LXC_HOST'."
            lxc file push -r -p "$BUILD_CONTEXT/" "$LXC_HOST/root"
            lxc exec "$LXC_HOST" -- docker build -t "$BCM_IMAGE_NAME" /root/build/
            IMAGE_TAGGED_FLAG=1
        else 
            echo "BCM_IMAGE_NAME was empty."
            exit
        fi
    else
        echo "The build context '$BUILD_CONTEXT' directory does not exist."
    fi
fi


if [[ $IMAGE_TAGGED_FLAG = 0 ]]; then
    lxc exec "$LXC_HOST" -- docker tag "$DOCKER_HUB_IMAGE" "$BCM_IMAGE_NAME"
fi

lxc exec "$LXC_HOST" -- docker push "$BCM_IMAGE_NAME"