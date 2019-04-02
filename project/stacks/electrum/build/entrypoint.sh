#!/bin/bash

set -e

if [[ -z $ENDPOINT ]]; then
    echo "ERROR: $ENDPOINT is not defined."
    exit
fi

# defaults are for mainnet.
CHAIN_TEXT=""
CHAIN_PORT="50001"
if [[ $CHAIN == "testnet" ]]; then
    CHAIN_TEXT="--testnet"
    CHAIN_PORT="60001"
    elif [[ $CHAIN == "regtest" ]]; then
    CHAIN_TEXT="--regtest"
    CHAIN_PORT="60401"
fi

python3 Electrum-3.3.4/run_electrum -D /home/user/.electrum --oneserver --server="$ENDPOINT:$CHAIN_PORT:t" "$CHAIN_TEXT"
