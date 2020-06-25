#!/bin/bash

# WARNING: Do NOT set -o here.
set -Eeu pipefail
cd "$(dirname "$0")"

NODE_NAME=

for i in "$@"; do
    case $i in
        --node-name=*)
            NODE_NAME="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

# Only run these commands if the swarm manager is up and running.
if lxc list --format csv | grep "RUNNING" | grep -q "$BCM_MANAGER_HOST_NAME"; then
    # We check to see if the "$BCM_MANAGER_HOST_NAME" node is running swarm services.
    if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it -t 2 -q 127.0.0.1:2377; then
        exit
    fi
    
    
    # delete the node IDs matching the NODE_NAME var.
    RESULT="$(lxc exec "$BCM_MANAGER_HOST_NAME" -- docker node ls --format '{{.ID}},{{.Hostname}}' | grep "$NODE_NAME" | cut -d: -f1)"
    NODE_ID="$(echo "$RESULT" | grep "$NODE_NAME" )"
    
    if [[ -n "$NODE_ID" ]]; then
        # we would only perform this step if we're not removing the last node.
        if ! echo "$RESULT" | grep -q "$BCM_MANAGER_HOST_NAME"; then
            lxc exec "$BCM_MANAGER_HOST_NAME" -- docker node remove "$NODE_ID" --force
        fi
    fi
fi
