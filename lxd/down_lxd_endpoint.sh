#!/bin/bash

# stop script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# go ahead and refresh the environment variables.
source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM) ]]; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

if [[ $BCM_BITCOIN_DELETE = "true" ]]; then
  echo "Calling ./bitcoin/down_lxd_bitcoin.sh"
  bash -c ./bitcoin/down_lxd_bitcoin.sh
else
  echo "BCM environment variables are configured to SKIP deletion of LXD host 'bitcoin'."
fi

if [[ $BCM_MANAGERS_DELETE = "true" ]]; then
  echo "Calling ./managers/down_lxd_managers.sh"
  bash -c ./managers/down_lxd_managers.sh
else
  echo "BCM environment variables are configured to SKIP deletion of LXD 'manager' hosts."
fi

if [[ $BCM_CACHESTACK_DELETE = "true" ]]; then
  echo "Calling ./cachestack/down_lxd_cachestack.sh"
  bash -c ./cachestack/down_lxd_cachestack.sh
else
  echo "BCM environment variables are configured to SKIP deletion of LXD host 'cachestack'."
fi

if [[ $BCM_GATEWAY_DELETE = "true" ]]; then
  echo "Calling ./gateway/down_lxd_gateway.sh"
  bash -c ./gateway/down_lxd_gateway.sh
else
  echo "BCM environment variables are configured to SKIP deletion of LXD host 'gateway'."
fi

# if set, we run the host_template down scripts.
if [[ $BCM_HOST_TEMPLATE_DELETE = "true" ]]; then
  echo "Calling ./host_template/down_lxd_host_template.sh"
  bash -c ./host_template/down_lxd_host_template.sh
else
  echo "BCM environment variables are configured to SKIP deletion of the BCM host template."
fi

# delete lxd network lxdbrBCMCSBrdg 
if [[ $(lxc network list | grep lxdbrBCMCSBrdg) ]]; then
    echo "Deleting lxd network 'lxdbrBCMCSBrdg'."
    lxc network delete lxdbrBCMCSBrdg
fi

if [[ $(lxc image list | grep bbb592c417b6) ]]; then
    echo "Deleting lxc image bbb592c417b6"
    lxc image delete bbb592c417b6
fi

