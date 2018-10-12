#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision `bcmnet_template`
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# delete container 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_container.sh $BCM_BCMNETTEMPLATE_CONTAINER_DELETE $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME"

# delete networks
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_network.sh $BCM_BCMNETTEMPLATE_NETWORK_LXDBR0CACHESTACK_DELETE lxdbrCachestack"

# delete 'BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/delete_lxc_storage.sh $BCM_BCMNETTEMPLATE_STORAGE_DOCKERVOL_DELETE bcm-bcmnet-template-dockervol"