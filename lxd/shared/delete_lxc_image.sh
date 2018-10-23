#!/usr/bin/env bash

IMAGE_NAME=$1

# delete lxc image
if [[ $(lxc image list | grep $IMAGE_NAME) ]]; then
    echo "Deleting lxc image '$IMAGE_NAME'."
    lxc image delete $IMAGE_NAME
fi
