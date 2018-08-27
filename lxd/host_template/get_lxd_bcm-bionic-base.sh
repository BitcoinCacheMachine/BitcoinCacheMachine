#!/bin/bash

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if [[ $(lxc image list | grep "bcm-bionic-base") ]]; then
  echo "LXC image 'bcm-bionic-base' already exists. Skipping downloading of the image from the public image server."
else
  echo "Copying the ubuntu/18.04 lxc image from the public 'image:' server to LXD remote '$(lxc remote get-default)'.'"
  lxc image copy images:ubuntu/18.04 $(lxc remote get-default): --alias bcm-bionic-base --auto-update
fi