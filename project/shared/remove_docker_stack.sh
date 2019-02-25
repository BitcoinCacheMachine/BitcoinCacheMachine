#!/bin/bash

set -Eeuox pipefail
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

if lxc list --format csv | grep -q "bcm-gateway-01"; then
    if ! lxc exec bcm-gateway-01 -- wait-for-it -t 2 127.0.0.1:2377; then
        echo "ERROR: The docker swarm service on bcm-gateway-01 is not working correctly. Can't remove stack '$STACK_NAME'."
        echo "You may need to re-run 'bcm provision'."
        exit
    fi
    
    if [[ "$(lxc exec bcm-gateway-01 -- docker stack ls --format "{{.Name}}" | grep -q "$STACK_NAME")" ]]; then
        lxc exec bcm-gateway-01 -- docker stack rm "$STACK_NAME"
    fi
fi
