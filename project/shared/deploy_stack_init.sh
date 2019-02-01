#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/env"

BCM_ENV_FILE_PATH=
DOCKERHUB_IMAGE=
BCM_IMAGE_NAME=
BCM_TIER_NAME=
BCM_STACK_NAME=
BCM_SERVICE_NAME=
BCM_IMAGE_TAG=latest

for i in "$@"; do
    case $i in
        --env-file-path=*)
            BCM_ENV_FILE_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [ ! -f $BCM_ENV_FILE_PATH ]; then
    echo "BCM_ENV_FILE_PATH not set. Exiting."
    exit
else
    echo "BCM_ENV_FILE_PATH: $BCM_ENV_FILE_PATH"
fi

# shellcheck disable=SC1090
source "$BCM_ENV_FILE_PATH"
DIR_NAME="$(dirname $BCM_ENV_FILE_PATH)"

if [[ -z $BCM_IMAGE_NAME ]]; then
    echo "BCM_IMAGE_NAME not set. Exiting."
    exit
fi

if [[ -z $BCM_TIER_NAME ]]; then
    echo "BCM_TIER_NAME not set. Exiting."
    exit
fi

if [[ -z $BCM_STACK_NAME ]]; then
    echo "BCM_STACK_NAME not set. Exiting."
    exit
fi

if [[ -z $BCM_SERVICE_NAME ]]; then
    echo "BCM_SERVICE_NAME not set. Exiting."
    exit
fi

if [[ -z $BCM_IMAGE_TAG ]]; then
    echo "BCM_IMAGE_TAG not set. Exiting."
    exit
fi

CONTAINER_NAME="bcm-$BCM_TIER_NAME-01"

bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --build-context=$DIR_NAME/build --container-name=$CONTAINER_NAME --image-name=$BCM_IMAGE_NAME --image-tag=$BCM_IMAGE_TAG"

BCM_STACK_FILE_DIRNAME=$(dirname $BCM_ENV_FILE_PATH)

# push the stack file.
lxc file push -p -r "$BCM_STACK_FILE_DIRNAME/" "bcm-gateway-01/root/stacks/$BCM_TIER_NAME/"

# run the stack by passing in the ENV vars.

CONTAINER_STACK_DIR="/root/stacks/$BCM_TIER_NAME/$BCM_STACK_NAME"

lxc exec bcm-gateway-01 -- bash -c "source $CONTAINER_STACK_DIR/env && env BCM_IMAGE_NAME=$BCM_PRIVATE_REGISTRY/$BCM_IMAGE_NAME docker stack deploy -c $CONTAINER_STACK_DIR/$BCM_STACK_FILE $BCM_STACK_NAME"