#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"


# delte container gateway-template
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE gateway-template"


# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi

####
# containers
####
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_image.sh $BCM_HOSTTEMPLATE_IMAGE_BCM_TEMPLATE_DELETE bcm-template"

####
# images
####
# delete image 'bcm-template'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_image.sh $BCM_HOSTTEMPLATE_IMAGE_BCM_TEMPLATE_DELETE bcm-template"

# delete image 'bcm-template'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_image.sh $BCM_HOSTTEMPLATE_IMAGE_BCM_BIONIC_BASE_DELETE bcm-bionic-base"

####
# profiles
####

# delete profile 'docker-privileged'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_DOCKER_PRIVILEGED_DELETE docker_privileged"

# delete image 'bcm-template'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_DOCKER_UNPRIVILEGED_DELETE docker_unprivileged"

# delete the profile bcm_disk
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_BCM_DISK_DELETE bcm_disk"


####
# storage
####
# delete lxc storage zfs backend
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_STORAGE_BCM_DATA_DELETE $BCM_ZFS_PREFIX-bcm_data"
