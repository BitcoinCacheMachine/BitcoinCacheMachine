#!/bin/bash

set -e

echo "Creating a LXD host template."

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create lxdbr0 if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbr0) ]]; then
  lxc network create lxdbr0
fi

# create the zfs cluster if it doesn't exist.
# $ZFS_POOL_NAME should be set before being called to allow for separation
# between applications.
if [[ -z $(lxc storage list | grep "bcm_data") ]]; then
  lxc storage create "bcm_data" zfs size=10GB
else
  echo "LXC storage pool 'bcm_data' already exists, skipping pool creation."
fi

bash -c ./up_lxd_profiles.sh

# if either download the bctemplate from a remote LXD point, or create it yourself.
if [[ $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE != "none" ]]; then
  echo "Attempting to download lxd image 'bctemplate' from remote LXD daemon $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE."
  lxc image copy $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE:bctemplate $(lxc remote get-default): --auto-update --copy-aliases
else
  bash -c ./create_lxd_host_template.sh
fi