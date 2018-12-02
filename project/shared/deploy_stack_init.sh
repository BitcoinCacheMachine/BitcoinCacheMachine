#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_ENV_FILE_PATH=
BCM_PRIVATE_REGISTRY="bcm-gateway-01:5010"
DOCKERHUB_IMAGE=
BCM_IMAGE_NAME=
BCM_HOST_TIER=
BCM_STACK_FILE_PATH=
BCM_STACK_NAME=
BCM_MAX_INSTANCES=2
BCM_SERVICE_NAME=
BCM_BUILD_FLAG=0

for i in "$@"
do
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
fi


echo "BCM_ENV_FILE_PATH: $BCM_ENV_FILE_PATH"
source "$BCM_ENV_FILE_PATH"
DIR_NAME="$(dirname $BCM_ENV_FILE_PATH)"

if [[ -z $BCM_IMAGE_NAME ]]; then
    echo "BCM_IMAGE_NAME not set. Exiting."
    exit
fi

if [[ -z $BCM_HOST_TIER ]]; then
    echo "BCM_HOST_TIER not set. Exiting."
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

CONTAINER_NAME="bcm-$BCM_HOST_TIER-01"
if [[ $BCM_BUILD_FLAG = 1 ]]; then
    bash -c "$BCM_LXD_OPS/docker_image_ops.sh --build --build-context=$DIR_NAME/build --container-name=$CONTAINER_NAME --priv-image-name=$BCM_IMAGE_NAME --registry=$BCM_PRIVATE_REGISTRY"
fi

if [[ $BCM_BUILD_FLAG = 0 ]]; then
    bash -c "$BCM_LXD_OPS/docker_image_ops.sh --container-name=$CONTAINER_NAME --image-name=$DOCKERHUB_IMAGE --priv-image-name=$BCM_IMAGE_NAME"
fi

BCM_STACK_FILE_DIRNAME=$(dirname $BCM_ENV_FILE_PATH)
BCM_STACK_FILE_PATH=$BCM_STACK_FILE_DIRNAME/$BCM_STACK_FILE

# push the stack file.
lxc file push -p "$BCM_STACK_FILE_PATH" "bcm-gateway-01/root/stacks/$BCM_HOST_TIER/$BCM_STACK_NAME.yml"

# run the stack by passing in the ENV vars.
lxc exec bcm-gateway-01 -- source "$BCM_ENV_FILE_PATH" && docker stack deploy -c "/root/stacks/$BCM_HOST_TIER/$BCM_STACK_NAME.yml" "$BCM_STACK_NAME"

# let's scale the schema registry count to UP TO 3.
CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    REPLICAS=$CLUSTER_NODE_COUNT

    if [[ $CLUSTER_NODE_COUNT -ge $BCM_MAX_INSTANCES ]]; then
        REPLICAS=$BCM_MAX_INSTANCES
    fi

    SERVICE_MODE=$(lxc exec bcm-gateway-01 -- docker service list --format "{{.Mode}}" --filter name="$BCM_STACK_NAME")
    if [[ $SERVICE_MODE = "replicated" ]]; then
        lxc exec bcm-gateway-01 -- docker service scale "$BCM_STACK_NAME""_""$BCM_SERVICE_NAME=$REPLICAS"
    fi
fi