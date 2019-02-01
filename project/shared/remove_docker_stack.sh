#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_ENV_FILE_PATH=
BCM_STACK_NAME=

for i in "$@"; do
    case $i in
        --env-file-path=*)
            BCM_ENV_FILE_PATH="${i#*=}"
            shift # past argument=value
        ;;
        --stack-name=*)
            BCM_STACK_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $BCM_ENV_FILE_PATH ]]; then
    if [ ! -f $BCM_ENV_FILE_PATH ]; then
        echo "BCM_ENV_FILE_PATH does not exist. Exiting."
        exit
    fi
    
    if [[ -z $BCM_STACK_NAME ]]; then
        echo "Error: BCM_ENV_FILE_PATH not set and BCM_STACK_NAME not specified. Exiting."
        exit
    fi
fi

if [[ -f $BCM_ENV_FILE_PATH ]]; then
    # shellcheck disable=SC1090
    source "$BCM_ENV_FILE_PATH"
    
    if [[ -z $BCM_TIER_NAME ]]; then
        echo "BCM_TIER_NAME not set. Exiting."
        exit
    fi
    
    if [[ -z $BCM_STACK_NAME ]]; then
        echo "BCM_STACK_NAME not set. Exiting."
        exit
    fi
    
    if lxc list --format csv | grep -q "bcm-gateway-01"; then
        if [[ "$(lxc exec bcm-gateway-01 -- docker info --format '{{.Swarm.LocalNodeState}}')" == "active" ]]; then
            if lxc exec bcm-gateway-01 -- docker stack ls --format "{{.Name}}" | grep -q "$BCM_STACK_NAME"; then
                lxc exec bcm-gateway-01 -- docker stack rm "$BCM_STACK_NAME"
                sleep 5
            fi
        fi
        
        lxc exec bcm-gateway-01 -- rm -Rf "/root/stacks/$BCM_TIER_NAME/$BCM_STACK_NAME"
    fi
fi
