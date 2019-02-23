#!/bin/bash

set -Eeux pipefail
cd "$(dirname "$0")"

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


# remove any nodes from the swarm that are no longer relevant.
if lxc list --format csv| grep "RUNNING" | grep -q "bcm-gateway-01"; then
    # if this command suceeds, then we can do the more specific info one.
    
    if lxc exec bcm-gateway-01 -- docker info --format '{{ .Swarm.LocalNodeState }}' == "active"; then
        for NODE_ID in $(lxc exec bcm-gateway-01 -- docker node list --filter name=$NODE_NAME --format '{{.ID}}'); do
            lxc exec bcm-gateway-01 -- docker node rm "$NODE_ID" --force
        done
    else
        echo "skipping"
    fi
fi
