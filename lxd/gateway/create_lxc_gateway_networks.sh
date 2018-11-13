#!/bin/bash

set -eu

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
MASTER_NODE=
if [[ $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME | wc -l) > 1 ]]; then
    # create and populate the required network

    # we have to do this for each cluster node
    for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
        HOST_ENDING=$(echo $endpoint | tail -c 2)
        echo "HOST_ENDING: $HOST_ENDING"
        lxc network create --target $endpoint bcmbrGWNat
        lxc network create --target $endpoint bcmNet
    done
fi

sleep 10

# bcmbrGWNat has outbound NAT
if [[ -z $(lxc network list | grep bcmbrGWNat) ]]; then
    lxc network create bcmbrGWNat ipv4.nat=true ipv6.nat=false
fi

# bcmNet does not have NAT. Hosts on this net can get outside
# via bcm-gateway LXD host docker services.
if [[ -z $(lxc network list | grep bcmNet) ]]; then
    lxc network create bcmNet ipv4.nat=false ipv6.nat=false dns.domain=bcmnet.tld ipv4.routing=false ipv4.address="192.168.4.254/24"
fi
