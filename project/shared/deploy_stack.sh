#!/bin/bash

set -Eeuox pipefail

# only use this if you have a docker stack .yml file that only takes the docker image as a a param

BCM_PRIVATE_REGISTRY=
DOCKERHUB_IMAGE=
BCM_IMAGE_NAME=
BCM_STACK_FILE_PATH=
BCM_STACK_NAME=
BCM_MAX_INSTANCES=2
BCM_SERVICE_NAME=
BCM_SERVICE_PORT=

for i in "$@"
do
case $i in
    --private-registry=*)
    BCM_PRIVATE_REGISTRY="${i#*=}"
    shift # past argument=value
    ;;
    --dockerhub-image=*)
    DOCKERHUB_IMAGE="${i#*=}"
    shift # past argument=value
    ;;
    --bcm-image-name=*)
    BCM_IMAGE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --lxc-host-tier=*)
    BCM_LXC_HOST_TIER="${i#*=}"
    shift # past argument=value
    ;;
    --stack-file-path=*)
    BCM_STACK_FILE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    --stack-name=*)
    BCM_STACK_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --max-instances=*)
    BCM_MAX_INSTANCES="${i#*=}"
    shift # past argument=value
    ;;
    --service-name=*)
    BCM_SERVICE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --service-port=*)
    BCM_SERVICE_PORT="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ -z $BCM_PRIVATE_REGISTRY ]]; then
    echo "BCM_PRIVATE_REGISTRY can't be empty."
    exit
fi

echo "BCM_STACK_FILE_PATH:  $BCM_STACK_FILE_PATH"

BCM_IMAGE="$BCM_PRIVATE_REGISTRY/$BCM_IMAGE_NAME"

bash -c "$BCM_LXD_OPS/image_pull_tag_push.sh --container-name=$BCM_LXC_HOST_TIER-01 --image-name=$DOCKERHUB_IMAGE --priv-image-name=$BCM_IMAGE"

# push the stack file.
lxc file push -p "$BCM_STACK_FILE_PATH" "bcm-gateway-01/root/stacks/$BCM_LXC_HOST_TIER/$BCM_STACK_NAME.yml"

# run the stack.
lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$BCM_IMAGE" BCM_SERVICE_PORT="$BCM_SERVICE_PORT" docker stack deploy -c "/root/stacks/$BCM_LXC_HOST_TIER/$BCM_STACK_NAME.yml" "$BCM_STACK_NAME"

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