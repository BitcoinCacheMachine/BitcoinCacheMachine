#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


# if bcm-template lxc image exists, run the gateway template creation script.
if ! lxc image list | grep -q "bcm-template"; then
    echo "Required LXC image 'bcm-template' does not exist. Exiting"
    exit
fi

./create_lxc_gateway_networks.sh

# create the 'bcm_gateway_profile' lxc profile
if ! lxc profile list | grep -q "bcm_gateway_profile"; then
    lxc profile create bcm_gateway_profile
fi

lxc profile edit bcm_gateway_profile < ./lxd_profiles/gateway.yml 

# let's make sure we have the dockertemplate to init from.
if ! lxc list | grep -q "bcm-host-template"; then
    echo "Error. LXC host 'bcm-host-template' doesn't exist."
    exit
fi


# get all the bcm-gateway-xx containers deployed to the cluster.
bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/spread_lxc_hosts.sh --hostname=gateway"

export GATEWAY_HOSTNAME="bcm-gateway-01"
export PRIVATE_REGISTRY="bcm-gateway-01:5010"
./provision_bcm-gateway.sh
