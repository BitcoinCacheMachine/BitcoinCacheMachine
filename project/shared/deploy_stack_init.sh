#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

MAX_INSTANCES=1

for i in "$@"; do
    case $i in
        --env-file-path=*)
            MAX_INSTANCES="${i#*=}"
            shift # past argument=value
        ;;
        --stack-name=*)
            BCM_STACK_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --service-name=*)
            SERVICE_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $BCM_STACK_NAME ]]; then
    echo "BCM_STACK_NAME cannot be empty."
    exit
fi

if [[ -z $SERVICE_NAME ]]; then
    echo "SERVICE_NAME cannot be empty."
    exit
fi

# let's scale the schema registry count to UP TO 3.
CLUSTER_NODE_COUNT=$(bcm cluster list --endpoints | wc -l)
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    REPLICAS=$CLUSTER_NODE_COUNT
    
    if [[ $CLUSTER_NODE_COUNT -ge $MAX_INSTANCES ]]; then
        REPLICAS=$MAX_INSTANCES
    fi
    
    SERVICE_MODE=$(lxc exec bcm-gateway-01 -- docker service list --format "{{.Mode}}" --filter name="$BCM_STACK_NAME")
    if [[ $SERVICE_MODE == "replicated" ]]; then
        lxc exec bcm-gateway-01 -- docker service scale "$BCM_STACK_NAME""_""$SERVICE_NAME=$REPLICAS"
    fi
fi
    exit
fi

if [[ -z $SERVICE_NAME ]]; then
    echo "SERVICE_NAME not set. Exiting."
    exit
fi

if [[ -z $BCM_IMAGE_TAG ]]; then
    echo "BCM_IMAGE_TAG not set. Exiting."
    exit
fi

CONTAINER_NAME="bcm-$BCM_TIER_NAME-01"
bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --docker-hub-image-name=$DOCKERHUB_IMAGE --build-context=$DIR_NAME/build --container-name=$CONTAINER_NAME --image-name=$BCM_IMAGE_NAME --image-tag=$BCM_IMAGE_TAG"

BCM_STACK_FILE_DIRNAME=$(dirname $BCM_ENV_FILE_PATH)

# push the stack file.
lxc file push -p -r "$BCM_STACK_FILE_DIRNAME/" "bcm-gateway-01/root/stacks/$BCM_TIER_NAME/"

# run the stack by passing in the ENV vars.

CONTAINER_STACK_DIR="/root/stacks/$BCM_TIER_NAME/$BCM_STACK_NAME"

lxc exec bcm-gateway-01 -- bash -c "source $CONTAINER_STACK_DIR/env && env BCM_IMAGE_NAME=$BCM_PRIVATE_REGISTRY/$BCM_IMAGE_NAME:$BCM_IMAGE_TAG BCM_LXC_HOST=$CONTAINER_NAME docker stack deploy -c $CONTAINER_STACK_DIR/$BCM_STACK_FILE $BCM_STACK_NAME"