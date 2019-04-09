#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./env

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


bash -c "$BCM_GIT_DIR/project/tiers/bitcoin/destroy.sh"

bash -c "$BCM_GIT_DIR/project/tiers/underlay/destroy.sh"

bash -c "$BCM_GIT_DIR/project/tiers/kafka/destroy.sh"

bash -c "$BCM_GIT_DIR/project/tiers/gateway/destroy.sh"


source ./env

# stop $HOST_NAME
if lxc list --format csv | grep "$HOST_NAME" | grep -q "RUNNING"; then
    lxc stop "$HOST_NAME"
fi

# delete $HOST_NAME
if lxc list --format csv | grep -q "$HOST_NAME"; then
    echo "Deleting $HOST_NAME lxd host."
    lxc delete "$HOST_NAME"
fi

if [[ $DELETE_BCM_IMAGE == 1 ]]; then
    # remove image bcm-template
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=$LXC_BCM_BASE_IMAGE_NAME"
fi

# remove image bcm-lxc-base
if [[ $DELETE_LXC_BASE == 1 ]]; then
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-lxc-base"
fi

# delete profile 'docker-privileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=docker_privileged"

# delete profile 'docker-unprivileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=docker_unprivileged"

if lxc network list --format csv | grep -q "bcmbr0"; then
    lxc network delete bcmbr0
fi

# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
CHAIN=$BCM_ACTIVE_CHAIN
if lxc project list | grep -q "$CHAIN"; then
    lxc project switch default
    lxc project delete "$CHAIN"
fi

# clean up any hanging images
bash -c "$BCM_GIT_DIR/project/shared/clear_unlabeled_lxc_images.sh"
