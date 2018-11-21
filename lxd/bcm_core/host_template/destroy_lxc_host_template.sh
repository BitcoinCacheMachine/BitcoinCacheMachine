#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"
source ./defaults.sh

# delete dockertemplate
if [[ ! -z $(lxc list | grep "bcm-host-template") ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force bcm-host-template
fi

if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_TEMPLATE_DELETE = 1 ]]; then
    # remove image bcm-template
    $BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh "bcm-template"
fi
# remove image bcm-lxc-base
if [[ $BCM_HOSTTEMPLATE_IMAGE_BCM_BASE_DELETE = 1 ]]; then
    $BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh bcm-lxc-base
fi

if [[ ! -z $(lxc storage list | grep "bcm-host-template-dockervol") ]]; then
    lxc storage delete "bcm-host-template-dockervol"
fi

# delete profile 'docker-privileged'
$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh --profile-name='docker_privileged'

# delete profile 'docker-unprivileged'
$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh --profile-name='docker_unprivileged'

if [[ ! -z $(lxc network list | grep bcmbr0) ]]; then
    lxc network delete bcmbr0
fi
