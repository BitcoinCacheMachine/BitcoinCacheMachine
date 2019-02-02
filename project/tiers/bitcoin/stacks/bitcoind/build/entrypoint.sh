#!/bin/bash

set -Eeux

echo "BITCOIND_CHAIN: $BITCOIND_CHAIN"
HOST_ENDING="01"
PROXY="bcm-gateway-$HOST_ENDING:9050"
TOR_CONTROL_HOST="bcm-gateway-$HOST_ENDING:9051"

wait-for-it -t 10 "$PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

GOGO_FILE=
if [[ $BITCOIND_CHAIN == "testnet" ]]; then
    GOGO_FILE=/data/testnet3/gogogo
    elif [[ $BITCOIND_CHAIN == "mainnet" ]]; then
    GOGO_FILE=/data/gogogo
else
    echo "Error: BITCOIND_CHAIN must be either 'testnet' or 'mainnet'."
    exit
fi

# we are going to wait for GOGO_FILE to appear before starting bitcoind.
# this allows the management plane to upload the blocks and/or chainstate.
while [ ! -f "$GOGO_FILE" ]
do
    sleep 2
    echo "."
done

if [[ $BITCOIND_CHAIN == "testnet" ]]; then
    bitcoind -testnet -conf=/root/.bitcoin/bitcoin.conf -datadir=/data -proxy="$PROXY" -torcontrol="$TOR_CONTROL_HOST"
    elif [[ $BITCOIND_CHAIN == "mainnet" ]]; then
    bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/data -proxy="$PROXY" -torcontrol="$TOR_CONTROL_HOST"
fi