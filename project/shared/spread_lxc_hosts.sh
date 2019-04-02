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

# let's get a bcm-gateway LXC instance on each cluster endpoint.
MASTER_NODE=$(bcm cluster list --endpoints | grep '01')
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    source ./env.sh --host-ending="$HOST_ENDING"
    
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
    if ! lxc list --format csv -c=n | grep -q "$LXC_HOSTNAME"; then
        PROFILE_NAME="bcm-$TIER_NAME-$BCM_VERSION"
        
        # first, check to see if LXC_BCM_BASE_IMAGE_NAME exists.  If not, we call $BCM_GIT_DIR/project/create_bcm_host_template.sh.sh
        if ! lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
            bash -c "$BCM_GIT_DIR/project/create_bcm_host_template.sh"
        fi
        
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
