#!/bin/bash

set -Eeuox pipefail
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

# delete profile 'bcm_disk'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=bcm_disk"

if lxc network list --format csv | grep "bcmbr0" | grep -q ",0,"; then
    lxc network delete bcmbr0
fi

#
if ! lxc project list | grep -q "default (current)"; then
    lxc project switch default
    lxc project delete "$BCM_PROJECT"
fi

# clean up any hanging images
bash -c "$BCM_GIT_DIR/project/shared/clear_unlabeled_lxc_images.sh"
