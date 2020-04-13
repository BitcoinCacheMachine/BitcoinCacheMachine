#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


DELETE_BCM_IMAGE=1
DELETE_LXC_BASE=0

for i in "$@"; do
    case $i in
        --keep-template=*)
            DELETE_BCM_IMAGE=0
            shift # past argument=value
        ;;
        --keep-bcmbase=*)
            DELETE_LXC_BASE=0
            shift # past argument=value
        ;;
        ---keep-all)
            DELETE_BCM_IMAGE=0
            DELETE_LXC_BASE=0
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

export TIER_NAME=manager

source "$BCM_GIT_DIR/project/tiers/env.sh"

# we get the hostname of the LXD container by getting its endpoint ID (which endpoint it's scheduled on)
for ENDPOINT in $CLUSTER_ENDPOINTS; do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # remove the host number from the hostname
    source "$BCM_GIT_DIR/project/tiers/env.sh" --host-ending="$HOST_ENDING"
    
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOSTNAME"
    
    CONTAINER_NAME="$LXC_HOSTNAME"
    if [[ $LXC_HOSTNAME == *"-bitcoin-"* ]]; then
        CONTAINER_NAME="bcm-bitcoin-$BCM_ACTIVE_CHAIN-$(printf %02d "$HOST_ENDING")"
    fi
    
    bash -c "$BCM_LXD_OPS/delete_dockerdisk.sh --container-name=$CONTAINER_NAME --endpoint=$ENDPOINT"
done

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmbrGWNat"

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmNet"

bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-manager-template"

PROFILE_NAME="bcm-manager"
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=$PROFILE_NAME"

if [[ $DELETE_BCM_IMAGE == 1 ]]; then
    # remove image bcm-template
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=$LXC_BCM_BASE_IMAGE_NAME"
fi

# remove image bcm-lxc-base
if [[ $DELETE_LXC_BASE == 1 ]]; then
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-lxc-base"
fi

# delete profile 'docker-privileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=privileged"

# delete profile 'docker-unprivileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=unprivileged"

# delete profile 'bcm_disk'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=bcm_disk"


if lxc network list --format csv | grep "bcmbr0" | grep -q ",0,"; then
    lxc network delete bcmbr0
fi

#
if ! lxc project list --format csv | grep -q "default (current)"; then
    lxc project switch default
    lxc project delete "$BCM_PROJECT"
fi

# clean up any hanging images
RESULT=$(lxc image list --format csv -c lf | grep "^," | cut -d "," -f 2)
for LXC_IMAGE_ID in $RESULT
do
    echo "INFO: Removing dangling LXC image with ID '$LXC_IMAGE_ID'."
    lxc image delete "$LXC_IMAGE_ID"
done
