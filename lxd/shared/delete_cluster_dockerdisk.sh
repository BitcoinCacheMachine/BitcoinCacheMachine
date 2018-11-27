#!/usr/bin/env bash

set -Eeuox pipefail

STORAGE_VOLUME_NAME=

for i in "$@"
do
case $i in
    --volume-name=*)
    STORAGE_VOLUME_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ -z $STORAGE_VOLUME_NAME ]]; then
    echo "Error. STORAGE_VOLUME_NAME was empty."
    exit
fi
echo "STORAGE_VOLUME_NAME: $STORAGE_VOLUME_NAME"

for ENDPOINT in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    VOLUME_NAME=$(echo "$STORAGE_VOLUME_NAME"-"$(printf %02d "$HOST_ENDING")"-dockerdisk)

    if lxc storage volume list bcm_btrfs | grep -q "$VOLUME_NAME"; then
        lxc storage volume delete bcm_btrfs "$VOLUME_NAME" --target "$ENDPOINT"
    fi
done