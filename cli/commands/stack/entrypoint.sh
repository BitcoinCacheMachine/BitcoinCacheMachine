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

function validateStackParam(){
    if [ -z "${STACK_NAME}" ]; then
        echo "Please provide a BCM stack name."
        cat "./$1/help.txt"
        exit
    fi
}


# make sure the user has sent in a valid command; quit if not.
if [[ $BCM_CLI_VERB != "list" && $BCM_CLI_VERB != "deploy" && $BCM_CLI_VERB != "remove" && $BCM_CLI_VERB != "clear" ]]; then
    echo "ERROR: The valid commands for 'bcm stack' are 'list', 'deploy', 'remove', and 'clear'."
    exit
fi

# if the current cluster is not configured, let's bring it into existence.
if [[ $(lxc remote get-default) == "local" ]]; then
    bcm cluster create
fi

if [[ $BCM_CLI_VERB == "deploy" ]]; then
    validateStackParam "$BCM_CLI_VERB";
    
    # running the stack up file.
    UP_FILE="$BCM_STACKS_DIR/$STACK_NAME/up.sh"
    if [[ -f "$UP_FILE" ]]; then
        bash -c "$UP_FILE" "$@"
    else
        echo "ERROR: Could not find '$UP_FILE'."
    fi
fi

if [[ $BCM_CLI_VERB == "remove"  ]]; then
    validateStackParam "$BCM_CLI_VERB";
    
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$STACK_NAME-$BCM_ACTIVE_CHAIN"
    
    # if the 'bck stack remove' command was executed with a '--volumes' flag, then we delete
    # the associated docker volumes this will be defined in a destroy.sh script in each stack directory.
    if [[ $BCM_VOLUMES_FLAG == 1 ]]; then
        # running the stack up file.
        DOWN_FILE="$BCM_STACKS_DIR/$STACK_NAME/destroy.sh"
        if [[ -f "$DOWN_FILE" ]]; then
            bash -c "$DOWN_FILE"
        else
            echo "ERROR: Could not find '$DOWN_FILE'."
        fi
    fi
fi

if [[ $BCM_CLI_VERB == "list" ]]; then
    PREFIX="-$BCM_ACTIVE_CHAIN"
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
        bcm stack remove "$STACK"
        sleep 5
    done
fi
