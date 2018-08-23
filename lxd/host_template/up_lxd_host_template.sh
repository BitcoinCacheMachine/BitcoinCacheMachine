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
  echo "'bcm_data' already exists, skipping pool creation."
fi

bash -c ./up_lxd_profiles.sh

# cache the active LXD endpoint so we don't have to use the LXD API mulitple times.
ACTIVE_LXD_ENDPOINT=$(lxc remote get-default)

echo "Copying lxd ubuntu:18.04 cloud image from the Internet."
lxc image copy ubuntu:18.04 $ACTIVE_LXD_ENDPOINT:

# only execute if bcm_data is non-zero
if [ ! -z bcm_data ]; then
  # initialize the LXD container to the active lxd endpoint. 
  lxc init ubuntu:18.04 $ACTIVE_LXD_ENDPOINT:dockertemplate \
    -p default \
    -p docker_priv \
    -s bcm_data

  lxc start $ACTIVE_LXD_ENDPOINT:dockertemplate
fi

sleep 5

# echo "Running apt update on dockertemplate."
# lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- apt update


# install docker - this does an 'apt update'
lxc file push ./get-docker.sh dockertemplate/root/get-docker.sh
#lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
lxc exec dockertemplate -- sh get-docker.sh >/dev/null

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on dockertemplate."
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- apt-get install wait-for-it tor jq curl ifmetric slurm tcptrack -y



lxc exec dockertemplate -- rm -rf /tmp/*

# stop the current template dockerd instance since we're about to create a snapshot
# Enable the docker daemon to start by default.
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- systemctl stop docker
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- systemctl enable docker

# grab the reference snapshot
## checking if this alleviates docker swarm troubles in lxc.
#https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
lxc exec $ACTIVE_LXD_ENDPOINT:dockertemplate -- touch /.dockerenv

#lxc file push ./sysctl.conf dockertemplate/etc/sysctl.conf
#lxc exec "$ACTIVE_LXD_ENDPOINT":dockertemplate -- chmod 0644 /etc/sysctl.conf

sleep 5

# stop the template since we don't need it running anymore.
lxc stop $ACTIVE_LXD_ENDPOINT:dockertemplate

lxc profile remove $ACTIVE_LXD_ENDPOINT:dockertemplate docker_priv

lxc snapshot $ACTIVE_LXD_ENDPOINT:dockertemplate dockerSnapshot