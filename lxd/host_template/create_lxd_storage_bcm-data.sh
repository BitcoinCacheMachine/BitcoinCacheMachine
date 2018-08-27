#!/bin/bash

# create the zfs cluster if it doesn't exist.
# $ZFS_POOL_NAME should be set before being called to allow for separation
# between applications.
if [[ -z $(lxc storage list | grep "bcm_data") ]]; then
  lxc storage create "bcm_data" zfs size=10GB
else
  echo "LXC storage pool 'bcm_data' already exists, skipping pool creation."
fi