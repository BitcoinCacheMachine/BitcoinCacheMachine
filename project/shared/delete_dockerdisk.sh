#!/bin/bash

set -Eeuox pipefail

LXC_HOSTNAME=
CLUSTER_ENDPOINT=

for i in "$@"; do
    case $i in
        --container-name=*)
            LXC_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoint=*)
            CLUSTER_ENDPOINT="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $LXC_HOSTNAME ]]; then
    echo "Error. LXC_HOSTNAME was empty."
    exit
fi

if [[ -z $CLUSTER_ENDPOINT ]]; then
    echo "Error. CLUSTER_ENDPOINT was empty."
    exit
fi

VOLUME_NAME="$LXC_HOSTNAME-dockerdisk"

if lxc storage list | grep -q bcm_btrfs; then
    if lxc storage volume list bcm_btrfs | grep "$VOLUME_NAME" | grep -q "$CLUSTER_ENDPOINT"; then
        lxc storage volume delete bcm_btrfs "$VOLUME_NAME" --target "$CLUSTER_ENDPOINT"
    fi
fi