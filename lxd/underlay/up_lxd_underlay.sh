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

# create the underlayprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep underlayprofile) ]]; then
    lxc profile create underlayprofile
fi

echo "Applying ./underlay_lxd_profile.yml to lxd profile 'underlayprofile'."
cat ./underlay_lxd_profile.yml | lxc profile edit underlayprofile

# create the underlay container.
if [[ -z $(lxc list | grep underlay) ]]; then
  #lxc copy dockertemplate/dockerSnapshot underlay

  lxc init ubuntu:18.04 -p default -p underlayprofile -s bcm_data underlay
else
  echo "LXC container 'underlay' already exists."
fi


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
    lxc profile apply underlay default,docker_unpriv,underlayprofile
    #lxc file push ./ufw.conf underlay/etc/default/ufw
    #lxc exec underlay -- chown root:root /etc/default/ufw

    lxc start underlay

    sleep 30

    # Update routing table so it routes traffic out the outside interface
    lxc exec underlay -- ifmetric eth1 50
else
    echo "LXD host 'underlay' is already in a running state. Exiting."
    exit 1
fi

bash -c ./stacks/dnsmasq/up_lxd_dnsmasq.sh

# allow outbound packets destinated on port 80 through to the outside untrusted gateway
lxc exec underlay -- ufw allow in on eth2 to any port 80
lxc exec underlay -- ufw allow in on eth2 to any port 443
lxc exec underlay -- ufw enable