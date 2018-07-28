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

# create the docker profile if it doesn't exist.
if [[ -z $(lxc profile list | grep docker) ]]; then
  lxc profile create docker
  cat ./shared/docker_lxd_profile.yml | lxc profile edit docker
else
  echo "Applying docker_lxd_profile.yml to lxd profile 'docker'."
  cat ./shared/docker_lxd_profile.yml | lxc profile edit docker
fi


# create the dockertemplate_profile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep dockertemplate_profile) ]]; then
  # create necessary templates
  lxc profile create dockertemplate_profile
  cat ./shared/lxd_profile_docker_template.yml | lxc profile edit dockertemplate_profile
else
  echo "LXD profile 'dockertemplate_profile' already exists, skipping profile creation."
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
if [[ $BC_CACHESTACK_STANDALONE = "true" ]]; then
  echo "Installing Bitcoin Cache Stack in standalone mode. Cache Stack will attach to the underlay via physical interface $BCS_TRUSTED_HOST_INTERFACE on $LXD_ENDPOINT."
  #TODO check to ensure the the macvlan interface is set.
  bash -c ./bcs/up_lxd.sh
else

  # if BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT is unset, then provision Cache Stack.
  if [[ -z $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT ]]; then
    if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
      echo "Installing Bitcoin Cache Stack + Bitcoin Cache Machine. Starting Cache Stack installation."
      bash -c ./bcs/up_lxd.sh
    fi
  else
    echo "Copying a prepared LXD system host image from $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT"
    lxc image copy $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT:bctemplate $LXD_ENDPOINT: --auto-update --copy-aliases
  fi

  export BCM_CACHE_STACK="cachestack"
  
  echo "Installing Bitcoin Cache Machine components."
  bash -c ./bcm/up_lxd.sh
fi
