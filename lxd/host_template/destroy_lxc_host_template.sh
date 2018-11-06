#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi

# remove image bcm-template
if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_TEMPLATE_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh bcm-template"
fi

# remove image bcm-bionic-base
if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_BIONIC_BASE_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh bcm-bionic-base"
fi

# delete profile 'docker-privileged'
if [[ $BCM_HOSTTEMPLATE_PROFILE_DOCKER_PRIVILEGED_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh docker_privileged"
fi

# delete profile 'docker-unprivileged'
if [[ $BCM_HOSTTEMPLATE_PROFILE_DOCKER_UNPRIVILIGED_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh docker_unprivileged"
fi

# delete profile 'bcm_disk'
if [[ $BCM_HOSTTEMPLATE_PROFILE_BCM_DISK_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh bcm_disk"
fi

# delete profile 'bcm_disk'
if [[ $BCM_STORAGE_bcm_zfs_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_storage.sh bcm_zfs"
fi

# delete profile 'bcm_disk'
if [[ $BCM_HOSTTEMPLATE_NETWORK_LXDBR0_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_network.sh lxdbr0"
fi
