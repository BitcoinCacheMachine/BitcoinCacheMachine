#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

CHAIN=${2:-}
if [ -z "${CHAIN}" ]; then
    cat ./help.txt
    exit
fi

# make sure the user has sent in a valid command; quit if not.
if [[ $CHAIN != "regtest" && $CHAIN != "testnet" && $CHAIN != "mainnet" ]]; then
    echo "ERROR: The valid commands for 'regtest', 'testnet', and 'mainnet'."
    exit
fi

# only do something if the user is actually changing chains.
if ! lxc project list | grep "(current)" | awk '{print $2}' | grep -q "$CHAIN"; then
    # make sure we're on the right remove
    if ! lxc project list | grep -q "$CHAIN"; then
        lxc project create "$CHAIN" -c features.images=false -c features.profiles=false
    fi
    
    lxc project switch "$CHAIN"
    echo "You are now targeting '$BCM_ACTIVE_CHAIN'"
fi
