#!/bin/bash

set -e

echo "Creating a 'host_template' that BCM components can use."

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

# copy the ubuntu/18.04/i386 lxc image from the public "image:" server to our active LXD remote.
lxc image copy images:ubuntu/18.04 $(lxc remote get-default): --alias bcm-bionic-base --auto-update

bash -c ./up_lxd_profiles.sh

bash -c ./create_lxd_host_template.sh