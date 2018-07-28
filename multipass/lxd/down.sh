#!/bin/bash

# stop script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# load the environment variables for the current LXD remote.
source ~/.bcm/lxd_endpoints.sh $(lxc remote get-default)

# quit if there are no BC environment variables
if [[ -z $(env | grep BC) ]]; then
  echo "BC variables not set. Please source ~/.bcm/lxd_endpoints.sh"
  exit
fi


# delete's the cache stack if defined by user.
function deleteCacheStack ()
{
  if [[ $BC_DELETE_CACHESTACK = "true" ]]; then
    echo "Calling Bitcoin Cache Machine down script."
    bash -c ./bcs/down_lxd.sh
  else
    echo "Skipping deletion of Bitcoin Cache Stack due to BC_DELETE_CACHESTACK not being 'true'."
  fi
}


# get or update the BCM host template git repo
if [[ $BC_CACHESTACK_STANDALONE = "true" ]]; then
  deleteCacheStack
else
  echo "Calling Bitcoin Cache Machine down script."
  bash -c ./bcm/down_lxd.sh

  deleteCacheStack
fi


# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep docker) ]]; then
    echo "Deleting docker lxd profile."
    lxc profile delete docker
else
    echo "Skipping deletion of docker lxd profile."
fi

# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep "dockertemplate_profile") ]]; then
    echo "Deleting dockertemplate_profile lxd profile."
    lxc profile delete dockertemplate_profile
else
    echo "Skipping deletion of dockertemplate_profile lxd profile."
fi

# delete lxd network lxdbrBCMBridge 
if [[ $(lxc network list | grep lxdbrBCMBridge) ]]; then
    echo "Deleting lxd network 'lxdbrBCMBridge'."
    lxc network delete lxdbrBCMBridge
else
    echo "Skipping deletion of lxd network lxdbrBCMBridge."
fi

