#!/bin/bash

# stop scrtip if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BC environment variables
if [[ -z $(env | grep BCM_) ]]; then
  echo "BCM variables not set. Please source BCM environment variables by typing 'bcm'."
  exit
fi

# ensure the host_template is available.
bash -c ./shared/create_host_template.sh

if [[ $BCM_GATEWAY_INSTALL = "true" ]]; then
  echo "Creating an LXD host template for 'gateway'. It shall be called 'manager-template' and will be snapshotted."
  bash -c ./gateway/create_lxd_gateway-template.sh

  
  echo "Deploying 'gateway' host(s)"
  bash -c ./gateway/up_lxd_gateway.sh
fi

if [[ $BCM_CACHESTACK_INSTALL = "true" ]]; then
    echo "Deploying 'cachestack' host(s)"
    bash -c ./cachestack/up_lxd_cachestack.sh
fi

if [[ $BCM_MANAGERS_INSTALL = "true" ]]; then
  echo "Deploying 'manager' host(s)"
  bash -c ./managers/up_lxd_managers.sh
fi

if [[ $BCM_BITCOIN_INSTALL = "true" ]]; then
  echo "Deploying 'bitcoin' host"
  bash -c ./bitcoin/up_lxd_bitcoin.sh
fi







# if [[ $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE = "none" ]]; then
#   # in this case, we deploy cachestack.
#   echo "Deploying local cachestack for BCM instance."
#   bash -c ./cachestack/up_lxd_cachestack.sh
# else
#   # in this assume the cachestack is defined in $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE
#   echo "Assuming external LXD endpoint '$BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE' is hosting a cachestack."
#   echo "Copying a prepared LXD system host image from $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE"
#   lxc image copy $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE:bctemplate $(lxc remote get-default): --auto-update --copy-aliases
# fi
