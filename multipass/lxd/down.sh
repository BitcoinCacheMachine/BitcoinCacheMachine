#!/bin/bash

# stop script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# load the environment variables for the current LXD remote.
source ~/.bcm/bcm_env.sh

# quit if there are no BC environment variables
if [[ -z $(env | grep BC) ]]; then
  echo "BC variables not set. Please source ~/.bcm/bcm_env.sh"
  exit
fi

# delete's the cache stack if defined by user.
function deleteCacheStack ()
{
  if [[ $BCS_DELETE_CACHESTACK = "true" ]]; then
    echo "Calling Bitcoin Cache Machine down script."
    bash -c ./bcs/down_lxd_cachestack.sh
  fi
}


# get or update the BCM host template git repo
if [[ $BCS_CACHESTACK_STANDALONE = "true" ]]; then
  deleteCacheStack
else
  echo "Calling Bitcoin Cache Machine down script."
  bash -c ./bcm/down_lxd_bcm.sh

  deleteCacheStack
fi

# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep "dockertemplate_profile") ]]; then
    echo "Deleting dockertemplate_profile lxd profile."
    lxc profile delete dockertemplate_profile
fi



# delete lxd network lxdbrBCMBridge 
if [[ $(lxc network list | grep lxdbrBCMBridge) ]]; then
    echo "Deleting lxd network 'lxdbrBCMBridge'."
    lxc network delete lxdbrBCMBridge
fi

# delete lxd storage pool 
if [[ ! -z $(lxc storage list | grep "$BC_ZFS_POOL_NAME" | grep "| 0") ]]; then
    echo "Deleting lxd storage pool '$BC_ZFS_POOL_NAME."
    lxc storage delete "$BC_ZFS_POOL_NAME"
else
  echo "Keeping lxc storage pool $BC_ZFS_POOL_NAME"
fi
