#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z "${BCM_CLI_VERB}" ]; then
    echo "Please provide a BCM stack command."
    cat ./help.txt
    exit
fi

if [[ $BCM_CLI_VERB == "deploy" ]]; then
    echo "bcm stack deploy"
    
    elif [[ $BCM_CLI_VERB == "remove" ]]; then
    echo "bcm stack remove"
    
else
    echo "ERROR: '$BCM_CLI_VERB' is not a valid command."
    cat ./help.txt
fi
