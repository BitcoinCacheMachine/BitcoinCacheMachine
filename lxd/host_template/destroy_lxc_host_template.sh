#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

# delete dockertemplate
if [[ ! -z $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi

# if [[ ! -z $(lxc network list | grep bcmbr0) ]]; then
#     lxc network delete bcmbr0
# fi

# remove image bcm-template
$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh bcm-template

# remove image bcm-bionic-base
if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_BIONIC_BASE_DELETE = "true" ]]; then
    $BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh bcm-bionic-base
fi

# delete profile 'docker-privileged'
$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh --profile-name='docker_privileged'

# delete profile 'docker-unprivileged'
$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh --profile-name='docker_unprivileged'
