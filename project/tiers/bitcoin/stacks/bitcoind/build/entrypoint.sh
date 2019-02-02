#!/bin/bash

set -Eeux

echo "BITCOIND_CHAIN: $BITCOIND_CHAIN"
HOST_ENDING="01"
PROXY="bcm-gateway-$HOST_ENDING:9050"
TOR_CONTROL_HOST="bcm-gateway-$HOST_ENDING:9051"

wait-for-it -t 10 "$PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

if [[ $BITCOIND_CHAIN == "testnet" ]]; then
    echo "Starting bitcoind with 'bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data'"
    bitcoind -testnet -conf=/home/bitcoin/bitcoin.conf -datadir=/data -proxy="$PROXY"
    elif [[ $BITCOIND_CHAIN == "mainnet" ]]; then
    echo "Starting bitcoind with 'bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data'"
    bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data -proxy="$PROXY"
fi