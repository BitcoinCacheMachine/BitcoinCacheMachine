#!/bin/bash

# stop scrtip if error is encountered.
set -e

# load the environment variables for the current LXD remote.
source ~/.bcm/lxd_endpoints.sh $(lxc remote get-default)

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BC environment variables
if [[ -z $(env | grep BC) ]]; then
  echo "BC variables not set. Please source ~/.bcm/lxd_endpoints.sh"
  exit
fi


# Installation branching logic. 
if [[ $BC_CACHESTACK_STANDALONE = "true" ]]; then
  echo "Installing Bitcoin Cache Stack in standalone mode. Cache Stack will attach to the underlay via physical interface $BCS_TRUSTED_HOST_INTERFACE on $LXD_ENDPOINT."
  #TODO check to ensure the the macvlan interface is set.
  bash -c ./bcs/up_lxd.sh
else

  if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
    echo "Installing Bitcoin Cache Stack + Bitcoin Cache Machine. Starting Cache Stack installation."
    bash -c ./bcs/up_lxd.sh
  fi

  export BCM_CACHE_STACK="cachestack"
  
  echo "Installing Bitcoin Cache Machine components."
  bash -c ./bcm/up_lxd.sh
fi
