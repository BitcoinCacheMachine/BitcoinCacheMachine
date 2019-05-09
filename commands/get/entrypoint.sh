#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE="${1:-}"
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$1"
else
    echo "Please provide a command."
    cat ./help.txt
    exit
fi

if [[ $BCM_CLI_VERB == "get-ip" ]]; then
    # returns the IP address where a client can reach docker swarm ports
    # also known as the macvlan interface IP address
    
    # let's check the cluster $BCM_RUNTIME_DIR/env file to see what deployment we're on
    # the use that info to determine which IP we should return.  Here's the mapping:
    # vm: MACVLAN interface IP
    # local: IP address on bcmLocalnet as provisioned by the bcmUnderlay up.sh
    # ssh: MACVLAN interface IP address assigned to underlay (of the remote SSH host)
    # onion: local SSH port-forwards to authenticated onion endpoints
    
    CLUSTER_NAME=$(lxc remote get-default)
    ENV_FILE="$BCM_WORKING_DIR/$CLUSTER_NAME/$CLUSTER_NAME-01/env"
    
    if [[ -f $ENV_FILE ]]; then
        
        source "$ENV_FILE"
        
        LXC_NETWORK_INTERFACE=
        if [[ $BCM_DRIVER == "local" ]]; then
            # valid for local deployment only.
            LXC_NETWORK_INTERFACE=eth1
            elif [[ $BCM_DRIVER == "multipass" ]]; then
            LXC_NETWORK_INTERFACE=eth2
            elif [[ $BCM_DRIVER == "ssh" ]]; then
            LXC_NETWORK_INTERFACE=eth2
        else
            echo "Error: $BCM_CLUSTER_DIR/env does not exist!"
            exit 1
        fi
        
        lxc info "$BCM_UNDERLAY_HOST_NAME" | grep "$LXC_NETWORK_INTERFACE:\\sinet\\s" | awk 'NF>1{print $NF}'
    fi
fi