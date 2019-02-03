#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

STACK_NAME=

for i in "$@"; do
    case $i in
        --stack-name=*)
            STACK_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $STACK_NAME ]]; then
    echo "STACK_NAME not set. Exiting."
    exit
fi

if lxc list --format csv | grep -q "bcm-gateway-01"; then
    if [[ "$(lxc exec bcm-gateway-01 -- docker info --format '{{.Swarm.LocalNodeState}}')" == "active" ]]; then
        if lxc exec bcm-gateway-01 -- docker stack ls --format "{{.Name}}" | grep -q "$STACK_NAME"; then
            lxc exec bcm-gateway-01 -- docker stack rm "$STACK_NAME"
        fi
    fi
fi
