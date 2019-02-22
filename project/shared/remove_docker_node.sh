#!/bin/bash

set -Eeuox pipefail

NODE_NAME=

for i in "$@"; do
    case $i in
        --node-name=*)
            NODE_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done


# remove swarm services related to kafka
if lxc list --format csv| grep "RUNNING" | grep -q "bcm-gateway-01"; then
    NODES="$(lxc exec bcm-gateway-01 -- docker node list --filter name=$NODE_NAME --format '{{.ID}}')"
    
    # if we got something back, let's remove them.
    if [[ ! -z "$NODES" ]]; then
        for NODE_ID in $NODES; do
            lxc exec bcm-gateway-01 -- docker node rm "$NODE_ID" --force
        done
    fi
fi