#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z "${BCM_CLI_VERB}" ]; then
    echo "Please provide a BCM stack command."
    cat ./help.txt
    exit
fi

# this is a list of stacks that we can deploy
# corresponds to directories in $BCM_STACK_DIR
STACKS=(clightning spark eclair esplora lightning-charge lnd opentimestamps spark)

if [[ $BCM_CLI_VERB == "deploy" ]]; then
    echo "deploy"
    
    elif [[ $BCM_CLI_VERB == "remove" ]]; then
    echo "test"
    elif [[ $BCM_CLI_VERB == "list" ]]; then
    echo "Supported BCM Stacks:"
    for STACK in ${STACKS[*]}
    do
        echo "  - $STACK";
    done
else
    echo "ERROR: '$BCM_CLI_VERB' is not a valid command."
    cat ./help.txt
fi
