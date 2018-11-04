#!/usr/bin/env bash

NETWORK_NAME=$1

# delete lxd storage gateway
if [[ $(lxc network list | grep $NETWORK_NAME) ]]; then
    lxc network delete $NETWORK_NAME
fi
