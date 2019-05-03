#!/bin/bash

set -Eeuo pipefail

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints | wc -l) -gt 1 ]]; then
    # create and populate the required network
    
    # we have to do this for each cluster node
    for endpoint in $(bcm cluster list --endpoints); do
        lxc network create --target "$endpoint" bcmbrGWNat
        lxc network create --target "$endpoint" bcmNet
    done
fi

function createBCMBRGW() {
    if ! lxc network list --format csv | grep -q bcmbrGWNat; then
        lxc network create bcmbrGWNat ipv4.nat=true ipv6.nat=false ipv6.address=none
    fi
}

function createBCMNet() {
    if ! lxc network list --format csv | grep -q bcmNet; then
        lxc network create bcmNet bridge.mode=fan dns.mode=dynamic
    fi
}

#
if lxc network list | grep bcmbrGWNat | grep -q PENDING; then
    createBCMBRGW
fi

if ! lxc network list | grep -q bcmbrGWNat; then
    createBCMBRGW
fi

#
if lxc network list | grep bcmNet | grep -q PENDING; then
    createBCMNet
fi

if ! lxc network list | grep -q bcmNet; then
    createBCMNet
fi