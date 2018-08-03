#!/bin/bash

# stop scrtip if error is encountered.
set -e

# load the environment variables for the current LXD remote.
source ~/.bcm/bcm_env.sh

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BC environment variables
if [[ -z $(env | grep BC) ]]; then
  echo "BC variables not set. Please source ~/.bcm/bcm_env.sh"
  exit
fi


# create the lxdbrBCMBridge network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrBCMBridge) ]]; then
    # lxdbrBCMBridge connects cachestack services to BCM instances running in the same LXD daemon.
    lxc network create lxdbrBCMBridge ipv4.nat=false ipv6.nat=false ipv6.address=none
    #ipv4.address=10.254.254.1/24
else
    echo "lxdbrBCMBridge already exists."
fi

# Installation branching logic. 
if [[ $BCS_CACHESTACK_STANDALONE = "true" ]]; then
  echo "Installing Bitcoin Cache Stack in standalone mode. Cache Stack will attach to the underlay via physical interface $BCS_TRUSTED_HOST_INTERFACE on $LXD_ENDPOINT."
  #TODO check to ensure the the macvlan interface is set.
  bash -c ./bcs/up_lxd_cachestack.sh
else
  # in this section, we're installing BCM, which requires at least 1 Cachestack
  # There are two options, either an external Cachestack is provided by the user
  # or there is no external cachestack, and hence we deploy one.

  if [[ $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT = "none" ]]; then
    # in this case, we deploy cachestack.
    echo "Deploying local cachestack for BCM instance."
    bash -c ./bcs/up_lxd_cachestack.sh
  else
    # in this assume the cachestack is defined in $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT
    echo "Assuming external LXD endpoint '$BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT' is hosting a cachestack."
    echo "Copying a prepared LXD system host image from $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT"
    lxc image copy $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT:bctemplate $LXD_ENDPOINT: --auto-update --copy-aliases
  fi

  export BCM_CACHE_STACK="$BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT"
  
  echo "Installing Bitcoin Cache Machine components."
  bash -c ./bcm/up_lxd_bcm.sh
fi
