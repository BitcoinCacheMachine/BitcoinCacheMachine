#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/.env"

# delete dockertemplate
if lxc list | grep -q "bcm-host-template"; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force bcm-host-template
fi

export BCM_HOSTTEMPLATE_IMAGE_BCM_TEMPLATE_DELETE=1
if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_TEMPLATE_DELETE == 1 ]]; then
    # remove image bcm-template
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-template"
fi

# remove image bcm-lxc-base
export BCM_HOSTTEMPLATE_IMAGE_BCM_BASE_DELETE=1
if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_BASE_DELETE == 1 ]]; then
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-lxc-base"
fi

# delete profile 'docker-privileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=docker_privileged"

# delete profile 'docker-unprivileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=docker_unprivileged"

if lxc network list --format csv | grep -q "bcmbr0"; then
    lxc network delete bcmbr0
fi
