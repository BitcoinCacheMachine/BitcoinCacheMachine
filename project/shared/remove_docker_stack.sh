#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

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

if [[ -z "$STACK_NAME" ]]; then
    echo "STACK_NAME not set. Exiting."
    exit
fi

if lxc list --format csv | grep -q "$BCM_GATEWAY_HOST_NAME"; then
    if ! lxc exec "$BCM_GATEWAY_HOST_NAME" -- wait-for-it -t 2 -q 127.0.0.1:2377; then
        echo "ERROR: The docker swarm service on $BCM_GATEWAY_HOST_NAME is not working correctly. Can't remove stack '$STACK_NAME'."
        echo "You may need to re-run 'bcm provision'."
        exit
    fi
    
    if lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker stack ls --format "{{.Name}}" | grep -q "$STACK_NAME"; then
        lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker stack remove "$STACK_NAME"
        sleep 5
    fi
fi
