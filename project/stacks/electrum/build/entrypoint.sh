#!/bin/bash

set -e

if [[ -z $ENDPOINT ]]; then
    echo "ERROR: $ENDPOINT is not defined."
    exit
fi

if [[ -z $SERVICE_PORT ]]; then
    echo "ERROR: $SERVICE_PORT is not defined."
    exit
fi

if [[ -z $CHAIN_TEXT ]]; then
    echo "ERROR: $CHAIN_TEXT is not defined."
    exit
fi

python3 Electrum-3.3.4/run_electrum -D /home/user/.electrum --oneserver --server="$ENDPOINT:$SERVICE_PORT:t" "$CHAIN_TEXT"
