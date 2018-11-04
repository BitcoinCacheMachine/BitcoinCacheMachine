#!/usr/bin/env bash

PROFILE_NAME=$1
LXD_PROFILE_FILE=$2

# create the $2 profile if it doesn't exist.
if [[ -z $(lxc profile list | grep $PROFILE_NAME) ]]; then
    lxc profile create $PROFILE_NAME
fi

echo "Applying $LXD_PROFILE_FILE to lxc profile '$PROFILE_NAME'."
cat $LXD_PROFILE_FILE | lxc profile edit $PROFILE_NAME
