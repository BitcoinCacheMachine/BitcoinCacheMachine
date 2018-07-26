#!/bin/bash

set -e

echo ""
echo "---------- bcm/bcs host template ----------------"
echo "Creating BCM/BCS LXD host template."

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create lxdbr0 if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbr0) ]]; then
  lxc network create lxdbr0
fi

# create the zfs cluster if it doesn't exist.
# $ZFS_POOL_NAME should be set before being called to allow for separation
# between applications.
if [[ -z $(lxc storage list | grep "bcm-data") ]]; then
  lxc storage create "$BC_ZFS_POOL_NAME" zfs size=10GB
else
  echo "$BC_ZFS_POOL_NAME already exists, skipping pool creation."
fi

# create the docker profile if it doesn't exist.
if [[ -z $(lxc profile list | grep docker) ]]; then
  # default profile has our root block device mapped to ZFS $ZFS_POOL_NAME
  lxc profile create docker
  cat ./docker_lxd_profile.yml | lxc profile edit docker
else
  echo "Applying docker_lxd_profile.yml to lxd profile 'docker'."
  cat ./docker_lxd_profile.yml | lxc profile edit docker
fi


# create the dockertemplate_profile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep dockertemplate_profile) ]]; then
  # create necessary templates
  lxc profile create dockertemplate_profile
  cat ./lxd_profile_docker_template.yml | lxc profile edit dockertemplate_profile
else
  echo "LXD profile 'dockertemplate_profile' already exists, skipping profile creation."
fi

# get the active LXD endpoint so we don't have to reference it all the time.
ACTIVE_LXD_ENDPOINT=$(lxc remote get-default)

echo "Copying lxd ubuntu:18.04 cloud image from the Internet."
lxc image copy ubuntu:18.04 $ACTIVE_LXD_ENDPOINT:

# only execute if BC_ZFS_POOL_NAME is non-zero
if [ ! -z $BC_ZFS_POOL_NAME ]; then
  # initialize the LXD container to the active lxd endpoint. 
  # -p tells it to connect to the user-defined ZFS storage pool (e.g., bcm_data/bcs_data)
  lxc init ubuntu:18.04 $ACTIVE_LXD_ENDPOINT:dockertemplate \
    -p docker \
    -p dockertemplate_profile \
    -s $BC_ZFS_POOL_NAME

  lxc start $ACTIVE_LXD_ENDPOINT:dockertemplate
fi

sleep 5

if [[ ! -z $BCM_CACHE_STACK_IP ]]; then
  echo "Running apt update on dockertemplate using HTTP_PROXY of http://$BCM_CACHE_STACK_IP:3128"
  lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate --env HTTP_PROXY=http://$BCM_CACHE_STACK_IP:3128 -- apt update

  echo "Installing required software on dockertemplate using HTTP_PROXY of http://$BCM_CACHE_STACK_IP:3128"
  lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate --env HTTP_PROXY=http://$BCM_CACHE_STACK_IP:3128 -- apt-get install wait-for-it -y
  lxc file push ./get-docker.sh dockertemplate/root/get-docker.sh
  lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate --env HTTP_PROXY=http://$BCM_CACHE_STACK_IP:3128 -- apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
  lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate --env HTTP_PROXY=http://$BCM_CACHE_STACK_IP:3128 -- sh get-docker.sh >/dev/null
else
  echo "Installing docker by downloading content from the Internet."
  lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
  lxc file push ./get-docker.sh dockertemplate/root/get-docker.sh
  lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- sh get-docker.sh >/dev/null
fi

# stop the current template dockerd instance since we're about to create a snapshot
# Enable the docker daemon to start by default.
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- systemctl stop docker
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- systemctl enable docker

# grab the reference snapshot
## checking if this alleviates docker swarm troubles in lxc.
#https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- touch /.dockerenv

lxc file push ./sysctl.conf dockertemplate/etc/sysctl.conf
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- chmod 0644 /etc/sysctl.conf

sleep 5

# stop the template since we don't need it running anymore.
lxc stop $ACTIVE_LXD_ENDPOINT:dockertemplate

lxc profile remove $ACTIVE_LXD_ENDPOINT:dockertemplate dockertemplate_profile

lxc snapshot $ACTIVE_LXD_ENDPOINT:dockertemplate dockerSnapshot