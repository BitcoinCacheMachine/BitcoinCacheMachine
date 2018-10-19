#!/bin/bash

set -e

echo "Starting 'up_lxc_host_template.sh'."

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create and populate the required networks
bash -c "$BCM_LXD_OPS/create_lxc_network_bridge_nat.sh $BCM_HOSTTEMPLATE_NETWORK_LXDBR0_CREATE lxdbr0"

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if [[ $(lxc image list | grep "bcm-bionic-base") ]]; then
  echo "LXC image 'bcm-bionic-base' already exists. Skipping downloading of the image from the public image server."
else
  echo "Copying the ubuntu/18.04 lxc image from the public 'image:' server to '$(lxc remote get-default):bcm-bionic-base'"
  lxc image copy images:ubuntu/18.04 $(lxc remote get-default): --alias bcm-bionic-base --auto-update
fi

####
# PROFILES
####
#default
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_DEFAULT_CREATE default $BCM_LXD_HOST_PROFILES/default.yml"
#bcm_disk
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_BCMDISK_CREATE bcm_disk $BCM_LXD_HOST_PROFILES/bcm_disk.yml"
#docker_unprivileged
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_DOCKER_UNPRIVILIEGED_CREATE docker_unprivileged $BCM_LXD_HOST_PROFILES/docker_unprivileged.yml"
#docker_privileged
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh $BCM_HOSTTEMPLATE_PROFILE_DOCKER_PRIVILEGED_CREATE docker_privileged $BCM_LXD_HOST_PROFILES/docker_privileged.yml"

bash -c ./create_lxc_host_template.sh