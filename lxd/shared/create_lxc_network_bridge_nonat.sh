#!/usr/bin/env bash

if [[ $1 = "true" ]]; then
    # create the lxdbrGateway network if it doesn't exist.
    if [[ -z $(lxc network list | grep $2) ]]; then
        if [[ -z $3 ]]; then
            # a bridged network network for mgmt and outbound NAT by hosts.
            lxc network create $2 ipv4.nat=false ipv6.nat=false
        else
            lxc network create $2 ipv4.nat=false ipv6.nat=false dns.mode=none
        fi
    fi
fi
