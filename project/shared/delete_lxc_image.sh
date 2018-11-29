#!/usr/bin/env bash

set -Eeuox pipefail

IMAGE_NAME=

for i in "$@"
do
case $i in
    --image-name=*)
    IMAGE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ -z $IMAGE_NAME ]]; then
    echo "LXC_IMAGE_NAME not set. Exiting."
    exit
fi

# quit if the template isn't there.
if lxc image list --format csv | grep -q "$IMAGE_NAME"; then
    echo "Deleting lxc image '$IMAGE_NAME'."
    lxc image delete "$IMAGE_NAME"
fi