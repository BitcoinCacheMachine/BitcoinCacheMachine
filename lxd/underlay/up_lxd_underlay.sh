#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision Cache Stack
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# ensure the host_template is available.
bash -c ../shared/create_host_template.sh

# set the current directory to ./
cd "$(dirname "$0")"

# create the lxdbrUnderlay network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrUnderlay) ]]; then
    # a bridged network created for outbound NAT for services on underlay.
    lxc network create lxdbrUnderlay ipv4.nat=true
else
    echo "lxdbrUnderlay already exists."
fi

# create the underlay container.
if [[ -z $(lxc list | grep underlay) ]]; then
  lxc copy dockertemplate/dockerSnapshot underlay
else
  echo "LXC container 'underlay' already exists."
fi

# create the underlayprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep underlayprofile) ]]; then
    lxc profile create underlayprofile
fi

echo "Applying ./underlay_lxd_profile.yml to lxd profile 'underlayprofile'."
cat ./underlay_lxd_profile.yml | lxc profile edit underlayprofile

#lxc profile device set underlayprofile eth1 nictype physical
echo "Updating lxc profile 'underlayprofile' eth1 parent to '$BCM_UNDERLAY_PHYSICAL_NETWORK_INTERFACE'."
lxc profile device set underlayprofile eth1 parent $BCM_UNDERLAY_PHYSICAL_NETWORK_INTERFACE

# ensure the host_template is available.
bash -c "../shared/create_dockervol.sh underlay"


# Apply the resulting profile and start the container.
if [[ -z $(lxc list | grep underlay | grep RUNNING) ]]; then
    # create a root device backed by the ZFS pool name passed in BC_ZFS_POOL_NAME.
    #lxc profile device add underlayprofile root disk path=/ pool=$BC_ZFS_POOL_NAME
    lxc profile apply underlay docker,underlayprofile

    lxc start underlay

    sleep 30

    # update routes to prefer eth0 for outbound access.
    lxc exec underlay -- ifmetric eth0 0
else
    echo "LXD host 'underlay' is already in a running state. Exiting."
    exit 1
fi

# # # underlay_INSIDE_IP is the IP that was assigned to the underlay macvlan interface.
# # underlay_INSIDE_IP=$(lxc exec underlay -- ip address show dev eth1 | grep "inet " |  awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

bash -c ./stacks/dnsmasq/up_lxd_dnsmasq.sh


