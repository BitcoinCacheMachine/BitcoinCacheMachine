#!/bin/bash

set -Eeuo pipefail

BCM_TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            BCM_TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $BCM_TIER_NAME ]]; then
    echo "BCM_TIER_NAME not set."
    exit
fi

# let's get a bcm-gateway LXC instance on each cluster endpoint.
MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    LXC_HOSTNAME="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
    LXC_DOCKERVOL="$LXC_HOSTNAME-dockerdisk"
    
    # only create the new storage volume if it doesn't already exist
    if ! lxc storage volume list bcm_btrfs | grep -q "$LXC_DOCKERVOL"; then
        # then this is normal behavior. Let's create the storage volume
        if [ "$ENDPOINT" != "$MASTER_NODE" ]; then
            echo "Creating volume '$LXC_DOCKERVOL' on storage pool bcm_btrfs on cluster member '$ENDPOINT'."
            lxc storage volume create bcm_btrfs "$LXC_DOCKERVOL" block.filesystem=ext4 --target "$ENDPOINT"
        else
            lxc storage volume create bcm_btrfs "$LXC_DOCKERVOL" block.filesystem=ext4
        fi
    else
        # but if it does exist, emit a WARNING that one already exists and will be used
        echo "WARNING: LXC storage volume '$LXC_DOCKERVOL' in bcm_btrfs storage pool already exists."
    fi
    
    # create the LXC host with the attached profiles.
    # TODO allow options of unprivileged.
    if ! lxc list --format csv -c=n | grep -q "$LXC_HOSTNAME"; then
        PROFILE_NAME='bcm_'"$BCM_TIER_NAME"'_profile'
        lxc init --target "$ENDPOINT" "$LXC_BCM_BASE_IMAGE_NAME" "$LXC_HOSTNAME" --profile=bcm_default --profile=docker_privileged --profile="$PROFILE_NAME"
    else
        echo "WARNING: LXC host '$LXC_HOSTNAME' already exists."
    fi
    
    if lxc storage volume list bcm_btrfs | grep "$LXC_DOCKERVOL" | grep -q "| 0 "; then
        if lxc storage volume show bcm_btrfs "$LXC_DOCKERVOL" | grep -q "location: $ENDPOINT"; then
            # let's attach the lxc storage volume 'dockervol' to the new LXC host for the docker backing.
            # only so long as its not already attached.
            
            lxc storage volume attach bcm_btrfs "$LXC_DOCKERVOL" "$LXC_HOSTNAME" dockerdisk path=/var/lib/docker
        fi
    else
        echo "WARNING: Your dockervol was already attached to '$LXC_HOSTNAME'."
    fi
done
