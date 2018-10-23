#!/usr/bin/env bash

LXC_CONTAINER_NAME=$1

if [[ $(lxc list | grep $LXC_CONTAINER_NAME) ]]; then
    # delete lxc container $2
    if [[ $(lxc info $LXC_CONTAINER_NAME | grep "Name: $LXC_CONTAINER_NAME") ]]; then
        echo "Deleting lxc container '$LXC_CONTAINER_NAME'."
        lxc delete --force $LXC_CONTAINER_NAME
    fi
fi