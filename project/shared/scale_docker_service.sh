#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

MAX_INSTANCES=1

for i in "$@"; do
    case $i in
        --env-file-path=*)
            MAX_INSTANCES="${i#*=}"
            shift # past argument=value
        ;;
        --stack-name=*)
            STACK_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --service-name=*)
            SERVICE_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $STACK_NAME ]]; then
    echo "STACK_NAME cannot be empty."
    exit
fi

if [[ -z $SERVICE_NAME ]]; then
    echo "SERVICE_NAME cannot be empty."
    exit
fi

# let's scale the schema registry count to UP TO 3.
CLUSTER_NODE_COUNT=$(bcm cluster list endpoints | wc -l)
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    REPLICAS=$CLUSTER_NODE_COUNT
    
    if [[ $CLUSTER_NODE_COUNT -ge $MAX_INSTANCES ]]; then
        REPLICAS=$MAX_INSTANCES
    fi
    
    SERVICE_MODE=$(lxc exec "$BCM_MANAGER_HOST_NAME" -- docker service list --format "{{.Mode}}" --filter name="$STACK_NAME")
    if [[ $SERVICE_MODE == "replicated" ]]; then
        lxc exec "$BCM_MANAGER_HOST_NAME" -- docker service scale "$STACK_NAME""_""$SERVICE_NAME=$REPLICAS"
    fi
fi
