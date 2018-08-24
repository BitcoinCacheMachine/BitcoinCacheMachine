#!/bin/bash

set -e

echo "Installing BCM LXD profile templates."

# default is given to each LXD container and defines eth0, which is always for outbound NAT management plane

# create the default profile if it doesn't exist.
if [[ -z $(lxc profile list | grep default) ]]; then
  lxc profile create default
fi

cat ./lxd_profiles/default.yml | lxc profile edit default

# create the bcm_disk profile if it doesn't exist.
if [[ -z $(lxc profile list | grep bcm_disk) ]]; then
  lxc profile create bcm_disk
fi

cat ./lxd_profiles/bcm_disk.yml | lxc profile edit bcm_disk

# create the docker_unpriv profile if it doesn't exist.
if [[ -z $(lxc profile list | grep "docker_unpriv") ]]; then
  # create necessary templates
  lxc profile create docker_unpriv
else
  echo "LXD profile 'docker_unpriv' already exists."
fi

echo "Applying docker_unprivileged.yml to lxc profile 'docker_unpriv'."
cat ./lxd_profiles/docker_unprivileged.yml | lxc profile edit docker_unpriv


# create the docker_priv profile if it doesn't exist.
if [[ -z $(lxc profile list | grep "docker_priv") ]]; then
  # create necessary templates
  lxc profile create docker_priv
else
  echo "LXD profile 'docker_priv' already exists."
fi

echo "Applying docker_privileged.yml to lxc profile 'docker_priv'."
cat ./lxd_profiles/docker_privileged.yml | lxc profile edit docker_priv