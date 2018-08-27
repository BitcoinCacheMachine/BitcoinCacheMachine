#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create the lxdbrGateway network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrGateway) ]]; then
    # a bridged network network for mgmt and outbound NAT by hosts.
    lxc network create lxdbrGateway ipv4.nat=true
else
    echo "lxdbrGateway already exists."
fi