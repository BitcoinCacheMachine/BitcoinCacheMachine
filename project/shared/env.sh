#!/bin/bash

set -Eeuo pipefail

HOST_ENDING="01"

for i in "$@"; do
    case $i in
        --host-ending=*)
            HOST_ENDING="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $HOST_ENDING ]]; then
    echo "Error: $HOST_ENDING is not defined."
    exit
fi

VERSION=$(echo "$BCM_VERSION" | tr '.' '-')
LXC_HOSTNAME="bcm-$TIER_NAME-$VERSION-$(printf %02d "$HOST_ENDING")-$BCM_ACTIVE_CHAIN"

export LXC_HOSTNAME="$LXC_HOSTNAME"
LXC_DOCKERVOL="$LXC_HOSTNAME-docker"
export LXC_DOCKERVOL="$LXC_DOCKERVOL"
export PROFILE_NAME="bcm-$TIER_NAME-$BCM_VERSION"
