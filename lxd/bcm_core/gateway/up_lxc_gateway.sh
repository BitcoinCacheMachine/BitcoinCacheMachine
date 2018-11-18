#!/bin/bash

set -eu
cd "$(dirname "$0")"


# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit
fi

./create_lxc_gateway_networks.sh

# create the 'bcm_gateway_profile' lxc profile
if [[ -z $(lxc profile list | grep "bcm_gateway_profile") ]]; then
    lxc profile create bcm_gateway_profile
fi

cat ./lxd_profiles/gateway.yml | lxc profile edit bcm_gateway_profile


# let's make sure we have the dockertemplate to init from.
if [[ -z $(lxc list | grep "bcm-host-template") ]]; then
    echo "Error. LXC host 'bcm-host-template' doesn't exist."
    exit
fi


# get all the bcm-gateway-xx containers deployed to the cluster.
bash -c "../spread_lxc_hosts.sh --hostname=gateway"

export GATEWAY_HOSTNAME="bcm-gateway-01"
export PRIVATE_REGISTRY="bcm-gateway-01:5010"
./provision_bcm-gateway.sh
