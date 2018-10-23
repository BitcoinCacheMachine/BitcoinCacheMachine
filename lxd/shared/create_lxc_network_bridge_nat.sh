#!/usr/bin/env bash

LXD_NETWORK_NAME=$1
NETWORK_TYPE=$2

# create the LXD_NETWORK_NAME network if it doesn't exist.
if [[ -z $(lxc network list | grep "$LXD_NETWORK_NAME") ]]; then
    # unfortunately the syntax is a bit different for a one node cluster.
    if [[ $BCM_CLUSTER_NAME = "DEV_MACHINE" ]]; then
        if [[ $NETWORK_TYPE = "bcmnet" ]]; then
            lxc network create $LXD_NETWORK_NAME ipv4.nat=false ipv6.nat=false dns.mode=none ipv4.dhcp=false ipv6.dhcp=false
        elif [[ $NETWORK_TYPE = "basicnat" ]]; then
            lxc network create $LXD_NETWORK_NAME ipv4.nat=true
        fi

        exit
    else
        for endpoint in $(bash -c $BCM_LOCAL_GIT_REPO/lxd/shared/get_lxc_cluster_members.sh)
        do
            lxc network create --target $endpoint $LXD_NETWORK_NAME
        done

        lxc network create $LXD_NETWORK_NAME ipv4.nat=true
    fi
fi
