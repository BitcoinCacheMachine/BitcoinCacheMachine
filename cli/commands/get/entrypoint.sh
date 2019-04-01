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
    # get-ip
    
    lxc info "$BCM_UI_HOST_NAME" | grep "eth1:\\sinet\\s" | awk 'NF>1{print $NF}'
fi