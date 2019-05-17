#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z "${BCM_CLI_VERB}" ]; then
    echo "Please provide a BCM stack command."
    cat ./help.txt
    exit
fi

STACK_NAME=${3:-}

function validateStackParam(){
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

# if the current cluster is not configured, let's bring it into existence.
if [[ $(lxc remote get-default) == "local" ]]; then
    if [[ $BCM_CLI_VERB != "list" ]]; then
        bcm cluster create
    else
        echo "ERROR: A BCM cluster does not exist. To create one, run 'bcm cluster create' or 'bcm stack start' command."
        exit
    fi
fi

BCM_BACKUP_DIR="$BCM_WORKING_DIR/$(lxc remote get-default)/backups"
export BACKUP_DIR="$BCM_BACKUP_DIR"

if [[ $BCM_CLI_VERB == "start" ]]; then
    validateStackParam "$BCM_CLI_VERB";
    
    # running the stack up file.
    UP_FILE="$BCM_STACKS_DIR/$STACK_NAME/up.sh"
    if [[ -f "$UP_FILE" ]]; then
        BCM_BACKUP_DIR="$BCM_BACKUP_DIR" bash -c "$UP_FILE" "$@"
    else
        echo "Error: Could not find '$UP_FILE'."
    fi
fi

if [[ $BCM_CLI_VERB == "stop"  ]]; then
    validateStackParam "$BCM_CLI_VERB";
    
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
            if [ ! -z ${STACK_DOCKER_VOLUMES+x} ]; then
                for DOCKER_VOLUME in $STACK_DOCKER_VOLUMES; do
                    bash -c "$BCM_GIT_DIR/project/shared/delete_docker_volume.sh --lxc-hostname=$TIER_NAME --stack-name=$STACK_NAME --volume-name=$DOCKER_VOLUME"
                done
            fi
        else
            echo "ERROR: Stack '$STACK_NAME' does not exist in the BCM repository."
            exit
        fi
    fi
fi

if [[ $BCM_CLI_VERB == "list" ]]; then
    PREFIX="-$BCM_ACTIVE_CHAIN"
    
    if lxc list --format csv --columns n,s | grep -q "$BCM_GATEWAY_HOST_NAME,STOPPED"; then
        lxc start "$BCM_GATEWAY_HOST_NAME"
        bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$BCM_GATEWAY_HOST_NAME"
    fi
    
    if lxc list --format csv -c=n | grep -q "$BCM_GATEWAY_HOST_NAME"; then
        CHAIN=$BCM_ACTIVE_CHAIN
        for STACK in $(lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$CHAIN")
        do
            STACK=${STACK%"$PREFIX"}
            echo "$STACK"
        done
    fi
fi

if [[ $BCM_CLI_VERB == "clear" ]]; then
    for STACK in $(bcm stack list)
    do
        bcm stack stop "$STACK" --delete
    done
fi
