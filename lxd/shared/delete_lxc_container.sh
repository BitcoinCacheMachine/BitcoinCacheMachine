#!/usr/bin/env bash

set -Eeuox pipefail

LXC_CONTAINER_NAME=

for i in "$@"
do
case $i in
    --container-name=*)
    LXC_CONTAINER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ -z $LXC_CONTAINER_NAME ]]; then
    echo "LXC_CONTAINER_NAME was empty. Exiting."
    exit
fi

if lxc list --format csv | grep -q "$LXC_CONTAINER_NAME"; then
    echo "Deleting lxc container '$LXC_CONTAINER_NAME'."
    lxc delete --force $LXC_CONTAINER_NAME
fi