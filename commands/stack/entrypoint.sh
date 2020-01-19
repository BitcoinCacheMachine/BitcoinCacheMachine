#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z "${BCM_CLI_VERB}" ]; then
    echo "Please provide a BCM stack command."
    cat ./help.txt
    exit
fi

STACK_NAME=${3:-}

function validateStackParam() {
    if [ -z "${STACK_NAME}" ]; then
        echo "Please provide a BCM stack name."
        cat "./$1/help.txt"
        exit
    fi
}

# make sure the user has sent in a valid command; quit if not.
if [[ $BCM_CLI_VERB != "list" && $BCM_CLI_VERB != "start" && $BCM_CLI_VERB != "stop" && $BCM_CLI_VERB != "clear" ]]; then
    echo "Error: The valid commands for 'bcm stack' are 'list', 'start', 'stop', and 'clear'."
    exit
fi


if [[ $BCM_CLI_VERB == "start" ]]; then
    STACK_NAME=
    if [ -z "${3:-}" ]; then
        echo "Please provide a BCM stack name."
        cat "./help.txt"
        exit
    else
        STACK_NAME="$3"
    fi
    
    # running the stack up file.
    UP_FILE="$BCM_STACKS_DIR/$STACK_NAME/up.sh"
    if [[ -f "$UP_FILE" ]]; then
        BCM_BACKUP_DIR="$BCM_BACKUP_DIR" bash -c "$UP_FILE" "$@"
    else
        echo "Error: BCM does not support stack '$STACK_NAME'. Check your spelling."
    fi
fi


if [[ $BCM_CLI_VERB == "stop" ]]; then
    validateStackParam "$BCM_CLI_VERB"
    
    STOP_SCRIPT="$BCM_STACKS_DIR/$STACK_NAME/stop.sh"
    if [[ -f $STOP_SCRIPT ]]; then
        bash -c "$STOP_SCRIPT"
    fi
    
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$STACK_NAME"
    
    # if the 'bck stack stop' command was executed with a '--delete' flag, then we delete
    # the associated docker volumes this will be defined in a destroy.sh script in each stack directory.
    if [[ $BCM_VOLUMES_FLAG == 1 ]]; then
        # let's source the stack file so we can get a list of associated docker volumes.
        STACK_ENV_FILE="$BCM_STACKS_DIR/$STACK_NAME/env.sh"
        if [[ -f $STACK_ENV_FILE ]]; then
            source "$STACK_ENV_FILE"
            
            # if there are some volumes defined, then we ca remove each one.
            # however, some containers do not write persistent data.
            if [ ! -z "${STACK_DOCKER_VOLUMES+x}" ]; then
                for DOCKER_VOLUME in $STACK_DOCKER_VOLUMES; do
                    LXC_HOSTNAME="$TIER_NAME"
                    
                    CONTAINER_NAME="$LXC_HOSTNAME"
                    if [[ $LXC_HOSTNAME == *"-bitcoin-"* ]]; then
                        CONTAINER_NAME="bcm-bitcoin-$BCM_ACTIVE_CHAIN-$(printf %02d "$HOST_ENDING")"
                    fi
                    
                    bash -c "$BCM_LXD_OPS/delete_docker_volume.sh --lxc-hostname=$CONTAINER_NAME --stack-name=$STACK_NAME --volume-name=$DOCKER_VOLUME"
                done
            fi
        else
            echo "ERROR: Stack '$STACK_NAME' does not exist in the BCM repository."
            exit
        fi
        
    fi
fi

if [[ $BCM_CLI_VERB == "clear" ]]; then
    bcm stack stop bitcoind --delete
    bcm stack stop torproxy --delete
    bcm stack stop toronion --delete
fi
