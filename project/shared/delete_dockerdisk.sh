#!/bin/bash

set -Eeuo pipefail

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

VOLUME_NAME="$LXC_HOSTNAME-docker"

if lxc storage volume list bcm --format csv | grep "$VOLUME_NAME" | grep -q "$CLUSTER_ENDPOINT"; then
    lxc storage volume delete bcm "$VOLUME_NAME" --target "$CLUSTER_ENDPOINT"
fi
