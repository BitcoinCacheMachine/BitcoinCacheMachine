#!/bin/bash

set -eu

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to ensure we have up-to-date ENV variables.
source "$BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# delete container 'bcm-gateway'
if [[ $BCM_GATEWAY_CONTAINER_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
fi

# delete BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME
if [[ $BCM_GATEWAY_STORAGE_DOCKERVOL_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME"
fi


if [[ $1 == "template" ]]; then
    # delte container gateway-template
    if [[ $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME"
    fi

    # delete the profile bcm-gateway-profile
    if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh bcm-gateway-profile"
    fi
    
    # delete lxc networks
    if [[ $BCM_GATEWAY_NETWORKS_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh lxdbrGateway"
    fi

    if [[ $BCM_GATEWAY_NETWORKS_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh lxdbrBCMNET"
    fi
fi

rm -rf ~/.bcm/runtime/$(lxc remote get-default)/$BCM_LXC_GATEWAY_CONTAINER_NAME