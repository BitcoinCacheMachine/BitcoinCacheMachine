#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_ENV_FILE_PATH=
BCM_PRIVATE_REGISTRY="bcm-gateway-01:5010"

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

BCM_STACK_FILE_DIRNAME=$(dirname $BCM_ENV_FILE_PATH)
BCM_STACK_FILE_PATH=$BCM_STACK_FILE_DIRNAME/$BCM_STACK_FILE

./deploy_stack.sh   --private-registry="$BCM_PRIVATE_REGISTRY" \
                    --dockerhub-image="$DOCKERHUB_IMAGE" \
                    --bcm-image-name="$BCM_IMAGE_NAME" \
                    --lxc-host-tier="$BCM_HOST_TIER" \
                    --stack-file-path="$BCM_STACK_FILE_PATH" \
                    --stack-name="$BCM_STACK_NAME" \
                    --max-instances="$BCM_MAX_INSTANCES" \
                    --service-name="$BCM_SERVICE_NAME"