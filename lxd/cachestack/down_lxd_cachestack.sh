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

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# delete container 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_CACHESTACK_CONTAINER_DELETE bcm-cachestack"

# delete the profile bcm-gateway-profile
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_profile.sh $BCM_CACHESTACK_PROFILE_CACHESTACK_STANDALONE_PROFILE_DELETE bcm-cachestack-standalone-profile"

# delete networks
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_CACHESTACK_NETWORK_LXDBR0CACHESTACK_DELETE lxdbrCachestack"


# delete 'bcm-gateway-dockervol'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_CACHESTACK_STORAGE_DOCKERVOL_DELETE bcm-cachestack-dockervol"

