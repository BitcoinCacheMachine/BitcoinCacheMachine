#!/bin/bash

set -Eeuox pipefail
echo "BCM /entrypoint.sh for electrumpersonalserver"

if [[ ! -z "$CHAIN" ]]; then
    if [[ $CHAIN == "testnet" ]]; then
        wait-for-it -t 300 bitcoindrpc-testnet:18332
        /root/.local/bin/electrum-personal-server "/root/.eps/$CHAIN.cfg"
    fi
else
    echo "Error: CHAIN not set."
fi

sleep 200