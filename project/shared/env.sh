#!/bin/bash

set -Eeuo pipefail

HOST_ENDING=

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
    echo "ERROR: $HOST_ENDING is not defined."
    exit
fi

VERSION=$(echo "$BCM_VERSION" | tr '.' '-')
LXC_HOSTNAME=
if [[ $TIER_NAME == "bitcoin" ]]; then
    # hostnames MUST be DNS compatible; thus removing '.'
    LXC_HOSTNAME="bcm-$TIER_NAME-$BCM_DEFAULT_CHAIN-$VERSION-$(printf %02d "$HOST_ENDING")"
else
    # hostnames MUST be DNS compatible; thus removing '.'
    LXC_HOSTNAME="bcm-$TIER_NAME-$VERSION-$(printf %02d "$HOST_ENDING")"
fi

export LXC_HOSTNAME="$LXC_HOSTNAME"
export LXC_DOCKERVOL="$LXC_HOSTNAME-docker"
export PROFILE_NAME="bcm-$TIER_NAME-$BCM_VERSION"