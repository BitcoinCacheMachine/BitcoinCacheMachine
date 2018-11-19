#!/bin/bash

set -eu

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME | wc -l) > 1 ]]; then
    # create and populate the required network

    # we have to do this for each cluster node
    for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
        lxc network create --target $endpoint bcmbrGWNat
        lxc network create --target $endpoint bcmNet
    done
fi

# bcmbrGWNat has outbound NAT
if [[ ! -z $(lxc network list | grep bcmbrGWNat | grep PENDING) || -z $(lxc network list | grep bcmbrGWNat) ]]; then
    lxc network create bcmbrGWNat ipv4.nat=true ipv6.nat=false
fi

# bcmNet does not have NAT. Hosts on this net can get outside
# via bcm-gateway LXD host docker services.
if [[ ! -z $(lxc network list | grep bcmNet | grep PENDING) || -z $(lxc network list | grep bcmNet)  ]]; then
    lxc network create bcmNet bridge.mode=fan
fi