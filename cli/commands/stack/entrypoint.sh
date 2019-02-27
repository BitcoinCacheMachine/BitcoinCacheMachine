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

# Regardless of components, you must specify whether you want to deploy it against testnet or mainnet.
CHAIN=
for i in "$@"; do
    case $i in
        --chain=*)
            CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done


function validateParams() {
    if [[ -z "$CHAIN" ]]; then
        echo "ERROR: A CHAIN MUST be specified.  Use --chain=<testnet|mainnet>"
        exit
    fi
    
    if [[ "$CHAIN" != "testnet" &&  "$CHAIN" != "mainnet" ]]; then
        echo "ERROR: CHAIN MUST be either 'testnet' or 'mainnet'."
        exit
    fi
}

function validateStackParam(){
    if [ -z "${STACK_NAME}" ]; then
        echo "Please provide a BCM stack name."
        cat "./$1/help.txt"
        exit
    fi
}


# this is a list of stacks that we can deploy
# corresponds to directories in $BCM_STACK_DIR
STACKS[0]="bitcoind"
STACKS[1]="clightning"
# STACKS[2]="lnd"
# STACKS[3]="eclaire"
# STACKS[esplora]=0
# STACKS[lightning-charge]=0
# STACKS[opentimestamps]=0
# STACKS[spark]=0

if [[ $BCM_CLI_VERB == "deploy" ]]; then
    validateStackParam "$BCM_CLI_VERB";
    validateParams;
    
    #echo "Deploying '$STACK_NAME' to bitcoind '$CHAIN'."
    UP_FILE="$BCM_STACKS_DIR/$STACK_NAME/up.sh"
    if [[ -f "$UP_FILE" ]]; then
        $UP_FILE "$@"
    else
        echo "ERROR: Could not find '$UP_FILE'."
    fi
    
    elif [[ $BCM_CLI_VERB == "rm" || $BCM_CLI_VERB == "remove"  ]]; then
    validateStackParam "$BCM_CLI_VERB";
    validateParams;
    
    #echo "Deploying '$STACK_NAME' to bitcoind '$CHAIN'."
    DESTROY_FILE="$BCM_STACKS_DIR/$STACK_NAME/destroy.sh"
    if [[ -f "$DESTROY_FILE" ]]; then
        $DESTROY_FILE "$@"
    else
        echo "ERROR: Could not find '$DESTROY_FILE'."
    fi
    
    elif [[ $BCM_CLI_VERB == "list" ]]; then
    DEPLOYED_STACKS="$(lxc exec bcm-gateway-01 -- docker stack list --format "{{ .Name }}")"
    for STACK in ${STACKS[*]}
    do
        if ! echo "$DEPLOYED_STACKS" | grep -q "$STACK"; then
            echo "$STACK";
        fi
    done
else
    echo "ERROR: '$BCM_CLI_VERB' is not a valid command."
    cat ./help.txt
fi
