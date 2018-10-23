#!/usr/bin/env bash

set -eu

echo "Starting 'up_lxc_host_template.sh'."

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to ensure we have up-to-date ENV variables.
source "$BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh"

#create and populate the required networks
if [[ $BCM_HOSTTEMPLATE_NETWORK_LXDBR0_CREATE = "true" ]]; then
  bash -c "$BCM_LXD_OPS/create_lxc_network_bridge_nat.sh lxdbr0 basicnat"
fi

# Let's createlx the ZFS storage pool for all operational images
if [[ -z $(lxc storage list | grep "bcm_data") ]]; then
  lxc storage create bcm_data zfs size=10GB
fi

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if [[ $(lxc image list | grep "bcm-bionic-base") ]]; then
  echo "LXC image 'bcm-bionic-base' already exists. Skipping downloading of the image from the public image server."
else
  echo "Copying the ubuntu/18.04 lxc image from the public 'image:' server to '$(lxc remote get-default):bcm-bionic-base'"
  lxc image copy images:ubuntu/18.04 local: --alias bcm-bionic-base --auto-update
fi

# create the default profile
if [[ $BCM_HOSTTEMPLATE_PROFILE_DEFAULT_CREATE = "true" ]]; then
  bash -c "$BCM_LXD_OPS/create_lxc_profile.sh default ./lxd_profiles/default.yml"
fi

# create the bcm_disk profile
if [[ $BCM_HOSTTEMPLATE_PROFILE_BCMDISK_CREATE = "true" ]]; then
  bash -c "$BCM_LXD_OPS/create_lxc_profile.sh bcm_disk ./lxd_profiles/bcm_disk.yml"
fi

# create the docker_unprivileged profile
if [[ $BCM_HOSTTEMPLATE_PROFILE_DOCKER_UNPRIVILIEGED_CREATE = "true" ]]; then
  bash -c "$BCM_LXD_OPS/create_lxc_profile.sh docker_unprivileged ./lxd_profiles/docker_unprivileged.yml"
fi

# create the docker_privileged profile
if [[ $BCM_HOSTTEMPLATE_PROFILE_DOCKER_PRIVILEGED_CREATE = "true" ]]; then
  bash -c "$BCM_LXD_OPS/create_lxc_profile.sh docker_privileged ./lxd_profiles/docker_privileged.yml"
fi

bash -c ./create_lxc_host_template.sh