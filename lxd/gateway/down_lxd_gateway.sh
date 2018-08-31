#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)


# delete container 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_GATEWAY_CONTAINER_DELETE bcm-gateway"

# delete 'bcm-gateway-dockervol'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_GATEWAY_STORAGE_DOCKERVOL_DELETE bcm-gateway-dockervol"

# delte container gateway-template
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE gateway-template"

# delete the profile bcm-gateway-profile
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE 'bcm-gateway-profile'"

# delete networks
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_GATEWAY_NETWORKS_DELETE lxdBrNowhere"
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_GATEWAY_NETWORKS_DELETE lxdBCMCSMGRNET"
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_GATEWAY_NETWORKS_DELETE lxdbrGateway"