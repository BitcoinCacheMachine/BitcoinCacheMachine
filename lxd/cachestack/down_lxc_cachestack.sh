#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision `cachestack`
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# delete container 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_CACHESTACK_CONTAINER_DELETE $BCM_LXC_CACHESTACK_CONTAINER_NAME"

# delete BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_CACHESTACK_STORAGE_DOCKERVOL_DELETE $BCM_LXC_CACHESTACK_STORAGE_DOCKERVOL_NAME"

if [[ $1 == "template" ]]; then
    # delete container 'bcm-gateway'
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_CACHESTACK_CONTAINER_DELETE $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME"

    # delete the profile bcm-gateway-profile
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_CACHESTACK_PROFILE_CACHESTACK_STANDALONE_PROFILE_DELETE bcm-cachestack-profile"

    # delete networks
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_CACHESTACK_NETWORK_LXDBR0CACHESTACK_DELETE lxdbrCachestack"

    # delete 'BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME'
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_CACHESTACK_STORAGE_DOCKERVOL_DELETE bcm-cachestack-dockervol"
    
fi