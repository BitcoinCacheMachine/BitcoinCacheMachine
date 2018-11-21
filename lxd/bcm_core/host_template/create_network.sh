#!/bin/bash

set -Eeuo pipefail

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME | wc -l) > 1 ]]; then
    # we run the following command if it's a cluster having more than 1 LXD node.
    for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
        lxc network create --target $endpoint bcmbr0
    done
else
    # but if it's just one node, we just create the network.
    lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
fi

# If there was more than one node, this is the last command we need
# to run to initiailze the network across the cluster. This isn't 
# executed when we have a cluster of size 1.
if [[ ! -z $(lxc network list | grep bcmbr0 | grep PENDING) ]]; then
    lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
fi