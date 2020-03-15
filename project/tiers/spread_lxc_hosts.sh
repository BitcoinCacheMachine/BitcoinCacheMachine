#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $TIER_NAME ]]; then
    echo "TIER_NAME not set."
    exit
fi

PROFILE_NAME="bcm-$TIER_NAME"

# let's get a bcm-manager LXC instance on each cluster endpoint.
for ENDPOINT in $CLUSTER_ENDPOINTS; do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    LXC_HOSTNAME="bcm-$TIER_NAME-$(printf %02d "$HOST_ENDING")"
    LXC_DOCKERVOL="$LXC_HOSTNAME-docker"
    
    # only create the new storage volume if it doesn't already exist
    if ! lxc storage volume list bcm --format csv | grep -q "$LXC_DOCKERVOL"; then
        echo "Creating volume '$LXC_DOCKERVOL' on the 'bcm' storage pool on cluster member '$ENDPOINT'."
        lxc storage volume create bcm "$LXC_DOCKERVOL" --target "$ENDPOINT"
    fi
    
    # create the LXC host with the attached profiles.
    if ! lxc list --format csv -c=n | grep -q "$LXC_HOSTNAME"; then
        # first, check to see if LXC_BCM_BASE_IMAGE_NAME exists.
        lxc init --target "$ENDPOINT" "$LXC_BCM_BASE_IMAGE_NAME" "$LXC_HOSTNAME" --profile="bcm_disk" --profile="docker_privileged" --profile="$PROFILE_NAME"
    else
        echo "WARNING: LXC host '$LXC_HOSTNAME' already exists."
    fi
    
    # last, attach the storage volume to the container.
    if ! lxc storage volume list bcm --format csv | grep "$LXC_DOCKERVOL" | grep -q ",0, "; then
        if lxc storage volume show bcm "$LXC_DOCKERVOL" | grep -q "location: $ENDPOINT"; then
            lxc storage volume attach bcm "$LXC_DOCKERVOL" "$LXC_HOSTNAME" dockerdisk path=/var/lib/docker
        fi
    fi
done
