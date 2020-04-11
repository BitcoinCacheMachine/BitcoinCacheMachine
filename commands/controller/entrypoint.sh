#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE="${2:-}"
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a 'controller' command."
    cat ./help.txt
    exit
fi

if [[ "$#" -le 2 ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./help.txt
        exit
    fi
fi

# now call the appropritate script.
if [[ $BCM_CLI_VERB == "reset" ]]; then
    bcm controller destroy
    bcm controller build
    elif [[ $BCM_CLI_VERB == "build" ]]; then
    ./build.sh
fi