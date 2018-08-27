#!/bin/bash

# stop scrtip if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# go ahead and refresh the environment variables.
source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM_) ]]; then
  echo "BCM variables not set. Please source BCM environment variables by typing 'bcm'."
  exit
fi

# If the admin hasn't specified an external LXD image server, then
# we can only assume that we need to build a base image from scratch. 
# it's best to centralize your image creation, but good for standalone deployments.
if [[ $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE = "none" ]]; then
  # then we're going to arrive at 'bcm-template' by creating it ourselves'
  bash -c ./host_template/up_lxd_host_template.sh
else
  # this is the logic that is taken when the administrator has specified a
  # custom LXD image server which is typical of home and offince network deployments
  if [[ $(lxc remote list | grep $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE) ]]; then
    echo "Attempting to download the LXC image named 'bcm-template' from the LXD remote $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE to LXD remote $(lxc remote get-default):bcm-template"
  else
    echo "Error! LXD remote $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE not found."
  fi
fi


# if instructed, serve the newly created snapshot to trusted LXD hosts.
if [[ $BCM_LXD_DOCKER_TEMPLATE_IMAGE_SERVE = "true" ]]; then
    # if the template doesn't exist, publish it so remote clients can reach it.
    if [[ -z $(lxc image list | grep "bcm-template") ]]; then
        echo "Publishing dockertemplate/bcmHostSnapshot snapshot as 'bcm-template' lxd image."
        lxc publish dockertemplate/bcmHostSnapshot --alias bcm-template --public
    fi
fi


if [[ $BCM_GATEWAY_INSTALL = "true" ]]; then
  echo "Deploying 'gateway' LXD host and associated components."
  bash -c ./gateway/up_lxd_gateway.sh
fi

# if [[ $BCM_CACHESTACK_INSTALL = "true" ]]; then
#     echo "Deploying 'cachestack' host(s)"
#     bash -c ./cachestack/up_lxd_cachestack.sh
# fi

# if [[ $BCM_MANAGERS_INSTALL = "true" ]]; then
#   echo "Deploying 'manager' host(s)"
#   bash -c ./managers/up_lxd_managers.sh
# fi

# if [[ $BCM_BITCOIN_INSTALL = "true" ]]; then
#   echo "Deploying 'bitcoin' host"
#   bash -c ./bitcoin/up_lxd_bitcoin.sh
# fi







# if [[ $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE = "none" ]]; then
#   # in this case, we deploy cachestack.
#   echo "Deploying local cachestack for BCM instance."
#   bash -c ./cachestack/up_lxd_cachestack.sh
# else
#   # in this assume the cachestack is defined in $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE
#   echo "Assuming external LXD endpoint '$BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE' is hosting a cachestack."
#   echo "Copying a prepared LXD system host image from $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE"
#   lxc image copy $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE:bctemplate $(lxc remote get-default): --auto-update --copy-aliases
# fi
