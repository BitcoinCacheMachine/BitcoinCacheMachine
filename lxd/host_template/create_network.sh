#!/bin/bash

set -eu

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME | wc -l) > 1 ]]; then
    # create and populate the required network

    # we have to do this for each cluster node
    for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
        HOST_ENDING=$(echo $endpoint | tail -c 2)
        echo "HOST_ENDING: $HOST_ENDING"
        lxc network create --target $endpoint bcmbr0
    done
fi

sleep 10

# bcmbrGWNat has outbound NAT
if [[ ! -z $(lxc network list | grep bcmbr0 | grep PENDING) ]]; then
    lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
fi