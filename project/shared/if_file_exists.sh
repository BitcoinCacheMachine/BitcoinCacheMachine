#!/bin/bash

set -Eeuo pipefail

# this is the LXC container that is running the
# docker container that has READ access to the target file
LXC_HOSTNAME=$1
STACK_NAME=$2

# this is the file path from the docker container perspective of the
# file we want to check the existence of. We return 1 if the file exists,
# otherwise 0
FILE_PATH=$3

CONTAINER_ID="$(lxc exec "$LXC_HOSTNAME" -- docker ps | grep "$STACK_NAME" | awk '{print $1;}')"
if [[ -z $CONTAINER_ID ]]; then
    exit 0
else
    lxc exec "$LXC_HOSTNAME" -- docker exec -t "$CONTAINER_ID" -- ls -lah "$FILE_PATH"
fi
