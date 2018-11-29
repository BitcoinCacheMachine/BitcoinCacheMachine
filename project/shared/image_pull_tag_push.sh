#!/bin/bash

LXC_HOST=
DOCKER_HUB_IMAGE=
PRIV_IMAGE_NAME=

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
    --priv-image-name=*)
    PRIV_IMAGE_NAME="${i#*=}"
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


if [[ -z $DOCKER_HUB_IMAGE ]]; then
    echo "DOCKER_HUB_IMAGE is empty. Exiting"
    exit
fi


if [[ -z $PRIV_IMAGE_NAME ]]; then
    echo "PRIV_IMAGE_NAME is empty. Exiting"
    exit
fi

if ! lxc list | grep -q "$LXC_HOST"; then
    echo "LXC host '$LXC_HOST' doesn't exist. Exiting"
    exit
fi


lxc exec "$LXC_HOST" -- docker pull "$DOCKER_HUB_IMAGE"
lxc exec "$LXC_HOST" -- docker tag "$DOCKER_HUB_IMAGE" "$PRIV_IMAGE_NAME"
lxc exec "$LXC_HOST" -- docker push "$PRIV_IMAGE_NAME"