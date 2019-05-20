#!/bin/bash

set -Eeuox pipefail
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

# if we are provisioning the bitcoin tier, let's go ahead and scope it to the active chain
if [[ $TIER_NAME == bitcoin* ]]; then
    PROFILE_NAME="bcm-bitcoin"
fi

# let's get a bcm-manager LXC instance on each cluster endpoint.
MASTER_NODE=$(bcm cluster list --endpoints | grep '01')
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    LXC_HOSTNAME="bcm-$TIER_NAME-$(printf %02d "$HOST_ENDING")"
    LXC_DOCKERVOL="$LXC_HOSTNAME-docker"
    
    # only create the new storage volume if it doesn't already exist
    if ! lxc storage volume list default | grep -q "$LXC_DOCKERVOL"; then
        # then this is normal behavior. Let's create the storage volume
        if [ "$ENDPOINT" != "$MASTER_NODE" ]; then
            echo "Creating volume '$LXC_DOCKERVOL' on the default storage pool on cluster member '$ENDPOINT'."
            lxc storage volume create default "$LXC_DOCKERVOL" block.filesystem=ext4 --target "$ENDPOINT"
        else
            lxc storage volume create default "$LXC_DOCKERVOL" block.filesystem=ext4
        fi
    else
        # but if it does exist, emit a WARNING that one already exists and will be used
        echo "WARNING: LXC storage volume '$LXC_DOCKERVOL' in the default storage pool already exists."
    fi
    
    # create the LXC host with the attached profiles.
    if ! lxc list --format csv -c=n | grep -q "$LXC_HOSTNAME"; then
        # first, check to see if LXC_BCM_BASE_IMAGE_NAME exists. 
        lxc init --target "$ENDPOINT" "$LXC_BCM_BASE_IMAGE_NAME" "$LXC_HOSTNAME" --profile=bcm_disk --profile=docker_privileged --profile="$PROFILE_NAME"
    else
        echo "WARNING: LXC host '$LXC_HOSTNAME' already exists."
    fi
    
    if lxc storage volume list default | grep "$LXC_DOCKERVOL" | grep -q "| 0 "; then
        if lxc storage volume show default "$LXC_DOCKERVOL" | grep -q "location: $ENDPOINT"; then
            # let's attach the lxc storage volume 'dockervol' to the new LXC host for the docker backing.
            # only so long as its not already attached.
            
            lxc storage volume attach default "$LXC_DOCKERVOL" "$LXC_HOSTNAME" dockerdisk path=/var/lib/docker
        fi
    else
        echo "WARNING: Your dockervol was already attached to '$LXC_HOSTNAME'."
    fi
done
