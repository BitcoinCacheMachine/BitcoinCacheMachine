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

if lxc list --format csv | grep -q "$BCM_MANAGER_HOST_NAME"; then
    
    # only if the manager is running
    if lxc list --format csv | grep "$BCM_MANAGER_HOST_NAME" | grep -q "RUNNING"; then
        if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it -t 2 -q 127.0.0.1:2377; then
            echo "Error: The docker swarm service on $BCM_MANAGER_HOST_NAME is not working correctly. Can't remove stack '$STACK_NAME'."
            exit
        fi
        
        if lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack ls --format "{{.Name}}" | grep -q "$STACK_NAME-$BCM_ACTIVE_CHAIN"; then
            lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack remove "$STACK_NAME-$BCM_ACTIVE_CHAIN" && sleep 20
        fi
        
        if [ -f "$BCM_STACKS_DIR/$STACK_NAME/env.sh" ]; then
            source "$BCM_STACKS_DIR/$STACK_NAME/env.sh"
            if [[ ! -z $TIER_NAME ]]; then
                if [[ $TIER_NAME != "kafka" ]]; then
                    TIER_LXC_HOST="$(lxc list --format csv --columns n | grep "bcm-$TIER_NAME")"
                    lxc exec "$TIER_LXC_HOST" -- docker system prune -f >> /dev/null &
                fi
            fi
        fi
    fi
fi
