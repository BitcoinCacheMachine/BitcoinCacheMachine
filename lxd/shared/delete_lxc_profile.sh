#!/usr/bin/env bash

PROFILE_NAME=$1

# delete lxd storage gateway
if [[ $(lxc profile list | grep "$PROFILE_NAME") ]]; then
    echo "Deleting lxd profile '$PROFILE_NAME'."
    lxc profile delete "$PROFILE_NAME"
fi
