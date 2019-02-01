#!/bin/bash

set -Eeuox

if [[ $BITCOIND_CHAIN == "testnet" ]]; then
    echo "Starting clightning testnet node."
    /root/lightning/lightningd/lightningd --conf=/root/.lightning/config -testnet
    
    elif [[ $BITCOIND_CHAIN == "mainnet" ]]; then
    
    echo "Starting clightning mainnet node."
    /root/lightning/lightningd/lightningd --conf=/root/.lightning/config
fi