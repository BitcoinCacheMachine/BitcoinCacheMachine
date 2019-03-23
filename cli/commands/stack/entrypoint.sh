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

function validateParams() {
    if [[ -z "$BCM_DEFAULT_CHAIN" ]]; then
        echo "ERROR: A CHAIN MUST be specified.  Use --chain=<testnet|mainnet>"
        exit
    fi
    
    if [[ "$BCM_DEFAULT_CHAIN" != "testnet" &&  "$BCM_DEFAULT_CHAIN" != "mainnet" && "$BCM_DEFAULT_CHAIN" != "regtest" ]]; then
        echo "ERROR: CHAIN MUST be either 'testnet', 'mainnet', or 'regtest'."
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

# install local LXD if it's not here already.
if ! snap list | grep -q lxd; then
    bash -c "$BCM_GIT_DIR/cli/commands/install/snap_install_lxd_local.sh"
fi

# this is a list of stacks that we can deploy
# corresponds to directories in $BCM_STACK_DIR
STACKS[0]="bitcoind"
STACKS[1]="clightning"
# STACKS[2]="lnd"
# STACKS[3]="eclair"
# STACKS[esplora]=0
# STACKS[lightning-charge]=0
# STACKS[opentimestamps]=0
# STACKS[spark]=0

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
    validateParams;
    
    #echo "Deploying '$STACK_NAME' to bitcoind '$BCM_DEFAULT_CHAIN'."
    UP_FILE="$BCM_STACKS_DIR/$STACK_NAME/up.sh"
    if [[ -f "$UP_FILE" ]]; then
        $UP_FILE "$@"
    else
        echo "ERROR: Could not find '$UP_FILE'."
    fi
fi

if [[ $BCM_CLI_VERB == "remove"  ]]; then
    validateStackParam "$BCM_CLI_VERB";
    validateParams;
    
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$STACK_NAME-$BCM_DEFAULT_CHAIN"
fi

if [[ $BCM_CLI_VERB == "list" ]]; then
    
    if lxc list --format csv | grep -q "bcm-gateway-01"; then
        DEPLOYED_STACKS="$(lxc exec bcm-gateway-01 -- docker stack list --format "{{ .Name }}")"
        for STACK in ${STACKS[*]}
        do
            if ! echo "$DEPLOYED_STACKS" | grep -q "$STACK"; then
                echo "$STACK";
            fi
        done
    fi
fi

if [[ $BCM_CLI_VERB == "clear" ]]; then
    bcm stack remove lightning-charge
    bcm stack remove btcpayserver
    bcm stack remove nbxplorer
    bcm stack remove spark
    bcm stack remove clightning
    bcm stack remove bitcoind
fi
