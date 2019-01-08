#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"

BCM_ENV_FILE_PATH=
DOCKERHUB_IMAGE=
BCM_IMAGE_NAME=
BCM_HOST_TIER=
BCM_STACK_NAME=
BCM_SERVICE_NAME=
BCM_BUILD_FLAG=0

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
fi

echo "BCM_ENV_FILE_PATH: $BCM_ENV_FILE_PATH"

# shellcheck disable=SC1090
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
if [[ $BCM_BUILD_FLAG == 1 ]]; then
	bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --build --build-context=$DIR_NAME/build --container-name=$CONTAINER_NAME --priv-image-name=$BCM_IMAGE_NAME"
fi

if [[ $BCM_BUILD_FLAG == 0 ]]; then
	bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --container-name=$CONTAINER_NAME --image-name=$DOCKERHUB_IMAGE --priv-image-name=$BCM_IMAGE_NAME"
fi

BCM_STACK_FILE_DIRNAME=$(dirname $BCM_ENV_FILE_PATH)

# push the stack file.
lxc file push -p -r "$BCM_STACK_FILE_DIRNAME/" "bcm-gateway-01/root/stacks/$BCM_HOST_TIER/"

# run the stack by passing in the ENV vars.

CONTAINER_STACK_DIR="/root/stacks/$BCM_HOST_TIER/$BCM_STACK_NAME"

lxc exec bcm-gateway-01 -- bash -c "source $CONTAINER_STACK_DIR/.env && env BCM_IMAGE_NAME=$BCM_PRIVATE_REGISTRY/$BCM_IMAGE_NAME docker stack deploy -c $CONTAINER_STACK_DIR/$BCM_STACK_FILE $BCM_STACK_NAME"
