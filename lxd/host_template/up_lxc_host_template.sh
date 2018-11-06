#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

echo "Starting 'up_lxc_host_template.sh'."


#create and populate the required networks
if [[ $(lxc network list | grep bcmbr0) ]]; then
  bash -c "$BCM_LXD_OPS/create_lxc_network_bridge_nat.sh bcmbr0 basicnat"
fi

# Let's createlx the ZFS storage pool for all operational images
if [[ -z $(lxc storage list | grep "bcm_zfs") ]]; then
  lxc storage create bcm_zfs zfs size=10GB
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
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh default ./lxd_profiles/default.yml"

# create the bcm_disk profile
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh bcm_disk ./lxd_profiles/bcm_disk.yml"

# create the docker_unprivileged profile
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh docker_unprivileged ./lxd_profiles/docker_unprivileged.yml"

# create the docker_privileged profile
bash -c "$BCM_LXD_OPS/create_lxc_profile.sh docker_privileged ./lxd_profiles/docker_privileged.yml"


bash -c ./create_lxc_host_template.sh