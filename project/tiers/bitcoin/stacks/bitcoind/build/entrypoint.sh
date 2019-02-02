#!/bin/bash

set -Eeux

echo "BITCOIND_CHAIN: $BITCOIND_CHAIN"
HOST_ENDING="01"
PROXY="bcm-gateway-$HOST_ENDING:9050"
TOR_CONTROL_HOST="bcm-gateway-$HOST_ENDING:9051"

wait-for-it -t 10 "$PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

# we are going to wait for /data/gogogo to appear before starting bitcoind.
# this allows the management plane to upload the blocks directory and/or chainstate.
while [ ! -f /data/gogogo ]
do
    sleep 2
    echo "."
done

if [[ $BITCOIND_CHAIN == "testnet" ]]; then
    bitcoind -testnet -conf=/home/bitcoin/bitcoin.conf -datadir=/data -proxy="$PROXY" -torcontrol="$TOR_CONTROL_HOST"
    elif [[ $BITCOIND_CHAIN == "mainnet" ]]; then
    bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data -proxy="$PROXY" -torcontrol="$TOR_CONTROL_HOST"
fi