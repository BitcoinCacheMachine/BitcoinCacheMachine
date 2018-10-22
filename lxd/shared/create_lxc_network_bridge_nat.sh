#!/bin/bash

PROCEED=$1
LXD_NETWORK_NAME=$2

if [[ $PROCEED = "true" ]]; then
    # create the lxdbrGateway network if it doesn't exist.
    if [[ -z $(lxc network list | grep "$LXD_NETWORK_NAME") ]]; then
        # a bridged network network for mgmt and outbound NAT by hosts.
        # TODO LOOP THROUGH CLUSTER MEMBERS.
        for endpoint in $(bash -c $BCM_LOCAL_GIT_REPO/lxd/shared/get_lxc_cluster_members.sh)
        do
            echo "$endpoint"
            lxc network create --target $endpoint $LXD_NETWORK_NAME
        done

        lxc network create $LXD_NETWORK_NAME ipv4.nat=true
    fi
fi


# output="$(lxc cluster list |  grep ONLINE | cut -f1,2 -d'|')"
# FOO_NO_WHITESPACE="$(echo -e "${output}" | tr -d '[:space:]')"
