#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


source ./env

DELETE_BCM_IMAGE=1
DELETE_LXC_BASE=1

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

bcm tier remove bitcoin >>/dev/null

bcm tier remove ui >>/dev/null

bcm tier remove kafka >>/dev/null

bcm tier remove gateway >>/dev/null

# stop bcm-host-template
if lxc list --format csv | grep "bcm-host-template" | grep -q "RUNNING"; then
    lxc stop bcm-host-template
fi

# delete bcm-host-template
if lxc list --format csv | grep -q "bcm-host-template"; then
    echo "Deleting bcm-host-template lxd host."
    lxc delete bcm-host-template
fi

if [[ $DELETE_BCM_IMAGE == 1 ]]; then
    # remove image bcm-template
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=$LXC_BCM_BASE_IMAGE_NAME"
fi

# remove image bcm-bionic-base
if [[ $DELETE_LXC_BASE == 1 ]]; then
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-bionic-base"
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
if lxc project list | grep -q "$BCM_PROJECT_NAME"; then
    lxc project switch default
    lxc project delete "$BCM_PROJECT_NAME"
fi

# clean up any hanging images
bash -c "$BCM_GIT_DIR/project/shared/clear_unlabeled_lxc_images.sh"
