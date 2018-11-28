#!/bin/bash

set -Eeuo pipefail

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME" | wc -l) -gt 1 ]]; then
    # create and populate the required network

    # we have to do this for each cluster node
    for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
        lxc network create --target "$endpoint" bcmbrGWNat
        lxc network create --target "$endpoint" bcmNet
    done
fi

# only do this if the network doesn't already exist.
if lxc network list | grep -q bcmbrGWNat; then
    # bcmbrGWNat has outbound NAT
    if [[ ! -z $(lxc network list | grep bcmbrGWNat | grep PENDING) || -z $(lxc network list | grep bcmbrGWNat)  ]]; then
        lxc network create bcmbrGWNat ipv4.nat=true ipv6.nat=false ipv6.address=none
    fi
fi

# only do this if the network doesn't already exist.
if lxc network list | grep -q bcmNet; then
    # we only run this block if we have a cluster of size 2 or more.
    if [[ ! -z $(lxc network list | grep bcmNet | grep PENDING) || -z $(lxc network list | grep bcmNet) ]]; then
        lxc network create bcmNet bridge.mode=fan dns.mode=dynamic
    fi
fi