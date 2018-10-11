#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# delete container 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_GATEWAY_CONTAINER_DELETE $BCM_LXC_GATEWAY_CONTAINER_NAME"

# delete BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_GATEWAY_STORAGE_DOCKERVOL_DELETE $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME"

if [[ $1 == "template" ]]; then
    # delte container gateway-template
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME"

    # delete the profile bcm-gateway-profile
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE 'bcm-gateway-profile'"

    # delete networks
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_GATEWAY_NETWORKS_DELETE lxdbrGateway"
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_GATEWAY_NETWORKS_DELETE lxdGWLocalNet"
fi

rm -rf ~/.bcm/runtime/$(lxc remote get-default)/$BCM_LXC_GATEWAY_CONTAINER_NAME