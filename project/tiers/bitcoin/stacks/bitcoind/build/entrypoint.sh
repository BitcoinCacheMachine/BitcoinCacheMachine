#!/bin/bash

set -Eeuox
# if [[ -f /secrets/bitcoin.conf ]]; then
#     echo "Copying /secrets/bitcoin.conf to /home/bitcoin/.bitcoin/bitcoin.conf"
#     cp /secrets/bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
#     chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin
# fi

echo "BITCOIND_CHAIN: $BITCOIND_CHAIN"

if [[ -z $LXC_HOST ]]; then
    echo "LXC_HOST not specified.  Cannot configure bitcoind proxy settings."
fi

if [[ $BITCOIND_CHAIN == "testnet" ]]; then
    echo "Starting bitcoind with 'bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data'"
    bitcoind -testnet -conf=/home/bitcoin/bitcoin.conf -datadir=/data -proxy="$LXC_HOST:9050"
    elif [[ $BITCOIND_CHAIN == "mainnet" ]]; then
    echo "Starting bitcoind with 'bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data'"
    bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data -proxy="$LXC_HOST:9050"
fi