#!/bin/bash

# WARNING: Do NOT set -o here.
set -Eeu pipefail
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

# Only run these commands if the swarm manager is up and running.
if lxc list --format csv | grep "RUNNING" | grep -q "bcm-gateway-01"; then
    # We check to see if the bcm-gateway-01 node is running swarm services.
    if ! lxc exec bcm-gateway-01 -- wait-for-it -t 2 -q 127.0.0.1:2377; then
        exit
    fi
    
    
    # delete the node IDs matching the NODE_NAME var.
    RESULT="$(lxc exec bcm-gateway-01 -- docker node ls --format '{{.ID}},{{.Hostname}}')"
    NODE_ID=
    NODE_ID="$(echo "$RESULT" | grep "$NODE_NAME" | cut -d: -f1)"
    
    if [[ ! -z $NODE_ID ]]; then
        # we would only perform this step if we're not removing the last node.
        if ! echo "$RESULT" | grep -q bcm-gateway-01; then
            lxc exec bcm-gateway-01 -- docker node rm "$NODE_ID" --force
        fi
    fi
fi
