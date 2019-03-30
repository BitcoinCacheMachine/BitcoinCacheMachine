#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

ENV_FILE=

for i in "$@"; do
    case $i in
        --env-file-path=*)
            ENV_FILE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: '$ENV_FILE' does not exist."
    exit
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "$STACK_NAME" ]]; then
    echo "STACK_NAME cannot be empty."
    exit
fi

if [[ -z "$SERVICE_NAME" ]]; then
    echo "SERVICE_NAME not set. Exiting."
    exit
fi

if [[ -z "$IMAGE_TAG" ]]; then
    echo "IMAGE_TAG not set. Exiting."
    exit
fi

HOST_ENDING="01"
CONTAINER_NAME="bcm-$BCM_TIER_NAME-$HOST_ENDING"
STACK_FILE_DIRNAME="$(dirname "$ENV_FILE")"

bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --docker-hub-image-name=$DOCKERHUB_IMAGE --build-context=$STACK_FILE_DIRNAME/build --container-name=$CONTAINER_NAME --image-name=$IMAGE_NAME --image-tag=$IMAGE_TAG"

# push the stack file.
lxc file push -p -r "$STACK_FILE_DIRNAME/" "$BCM_GATEWAY_HOST_NAME/root/stacks/$BCM_TIER_NAME/"

# run the stack by passing in the ENV vars.
CONTAINER_STACK_DIR="/root/stacks/$BCM_TIER_NAME/$STACK_NAME"
lxc exec $BCM_GATEWAY_HOST_NAME -- bash -c "source $CONTAINER_STACK_DIR/env && env IMAGE_FQDN=$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG BCM_LXC_HOST=$CONTAINER_NAME docker stack deploy -c $CONTAINER_STACK_DIR/$STACK_FILE $STACK_NAME"