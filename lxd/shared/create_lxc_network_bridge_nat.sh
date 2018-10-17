#!/bin/bash


if [[ $1 = "true" ]]; then
    # create the lxdbrGateway network if it doesn't exist.
    if [[ -z $(lxc network list | grep $2) ]]; then
        # a bridged network network for mgmt and outbound NAT by hosts.
        # TODO LOOP THROUGH CLUSTER MEMBERS.


        lxc network create $2 ipv4.nat=true
    fi
fi
