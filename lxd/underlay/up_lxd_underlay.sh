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

# create the lxdbrUnderlay network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrUnderlay) ]]; then
    # a bridged network network for mgmt and outbound NAT by hosts.
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
echo "Setting lxc profile 'underlayprofile' eth1 (untrusted outside) parent to physical interface '$BCM_UNDERLAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE'."
lxc profile device set underlayprofile eth1 parent $BCM_UNDERLAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE

#lxc profile device set underlayprofile eth2 nictype physical
echo "Setting lxc profile 'underlayprofile' eth2 (trusted inside) parent to physical interface '$BCM_UNDERLAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
lxc profile device set underlayprofile eth2 parent $BCM_UNDERLAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE

# ensure the host_template is available.
bash -c "../shared/create_dockervol.sh underlay"


# Apply the resulting profile and start the container.
if [[ -z $(lxc list | grep underlay | grep RUNNING) ]]; then
    # create a root device backed by the ZFS pool name passed in bcm_data.
    #lxc profile device add underlayprofile root disk path=/ pool=$bcm_data
    lxc profile apply underlay docker,underlayprofile

    # configure dockerd
    lxc file push ./daemon.json underlay/etc/docker/daemon.json

    lxc start underlay

    # systemd binds to 53 be default, remove it and let's use docker-hosted dnsmasq container
    lxc exec underlay -- systemctl stop systemd-resolved
    lxc exec underlay -- systemctl disable systemd-resolved


    sleep 30

    # Update routing table so it routes traffic out the outside interface
    lxc exec underlay -- ifmetric eth3 25
else
    echo "LXD host 'underlay' is already in a running state. Exiting."
    exit 1
fi


