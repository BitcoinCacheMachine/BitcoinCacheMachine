#!/bin/bash

# stop scrtip if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BC environment variables
if [[ -z $(env | grep BCM_) ]]; then
  echo "BC variables not set. Please BCM environment variables."
  exit
fi

# ensure the host_template is available.
bash -c ./shared/create_host_template.sh

if [[ $BCM_UNDERLAY_INSTALL = "true" ]]; then
  echo "Installing 'underlay' host."
  bash -c ./underlay/up_lxd_underlay.sh
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


# if [[ $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT = "none" ]]; then
#   # in this case, we deploy cachestack.
#   echo "Deploying local cachestack for BCM instance."
#   bash -c ./cachestack/up_lxd_cachestack.sh
# else
#   # in this assume the cachestack is defined in $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT
#   echo "Assuming external LXD endpoint '$BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT' is hosting a cachestack."
#   echo "Copying a prepared LXD system host image from $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT"
#   lxc image copy $BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT:bctemplate $(lxc remote get-default): --auto-update --copy-aliases
# fi
