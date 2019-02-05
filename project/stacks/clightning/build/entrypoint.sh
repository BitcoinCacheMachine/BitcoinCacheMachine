#!/bin/bash

set -Eeux

source /bcm/runtime_helper.sh

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

# we are going to wait for GOGO_FILE to appear before starting bitcoind.
# this allows the management plane to upload the blocks and/or chainstate.
while [ ! -f "$GOGO_FILE" ]
do
    sleep .5
    printf '.'
done

if [[ $CHAIN == "testnet" ]]; then
    /root/lightning/lightningd/lightningd --conf=/root/.lightning/config -testnet
    elif [[ $CHAIN == "mainnet" ]]; then
    /root/lightning/lightningd/lightningd --conf=/root/.lightning/config
fi
