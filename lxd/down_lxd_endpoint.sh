#!/bin/bash

# stop script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM) ]]; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

if [[ $BCM_BITCOIN_DELETE = "true" ]]; then
  echo "Calling ./bitcoin/down_lxd_bitcoin.sh"
  bash -c ./bitcoin/down_lxd_bitcoin.sh
fi

if [[ $BCM_MANAGERS_DELETE = "true" ]]; then
  echo "Calling ./managers/down_lxd_managers.sh"
  bash -c ./managers/down_lxd_managers.sh
fi

if [[ $BCM_CACHESTACK_DELETE = "true" ]]; then
  echo "Calling ./cachestack/down_lxd_cachestack.sh"
  bash -c ./cachestack/down_lxd_cachestack.sh
fi

if [[ $BCM_UNDERLAY_DELETE = "true" ]]; then
  echo "Calling ./underlay/down_lxd_underlay.sh"
  bash -c ./underlay/down_lxd_underlay.sh
fi

if [[ $BCM_HOST_TEMPLATE_DELETE = "true" ]]; then
  echo "Calling ./host_template/down_lxd_host_template.sh"
  bash -c ./host_template/down_lxd_host_template.sh
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

