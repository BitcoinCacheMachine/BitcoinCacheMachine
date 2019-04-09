#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh

if [[ -z "$TOR_PROXY" ]]; then
    echo "ERROR:  TOR_PROXY could not be determined."
    exit
fi
wait-for-it -t 10 "$TOR_PROXY"

if [[ -z "$TOR_CONTROL" ]]; then
    echo "ERROR:  TOR_CONTROL could not be determined."
    exit
fi
wait-for-it -t 10 "$TOR_CONTROL"

if [[ ! -z "$CHAIN" ]]; then
    # defaults are for mainnet
    CHAIN_TEXT=""
    RPC_PORT="8332"
    ZMQ_PORT="9332"
    GOGO_FILE=/root/.bitcoin/gogo
    
    if [[ "$CHAIN" == "testnet" ]]; then
        GOGO_FILE=/root/.bitcoin/testnet3/gogo
        CHAIN_TEXT="-testnet"
        RPC_PORT="18332"
        ZMQ_PORT="19332"
        elif [[ "$CHAIN" == "regtest" ]]; then
        GOGO_FILE=/root/.bitcoin/regtest/gogo
        CHAIN_TEXT="-regtest"
        RPC_PORT="28332"
        ZMQ_PORT="29332"
    else
        echo "Error: CHAIN must be either 'testnet', 'mainnet', or 'regtest'."
        exit
    fi
    
    # wait for the managementt plane.
    bash -c "/bcm/wait_for_gogo.sh --gogofile=$GOGO_FILE"
    
    # run bitcoind
    bitcoind -conf=/root/.bitcoin/bitcoin.conf \
    -datadir=/root/.bitcoin \
    -proxy="$TOR_PROXY" \
    -torcontrol="$TOR_CONTROL" \
    -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:$ZMQ_PORT" \
    -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:$ZMQ_PORT" \
    -rpcbind="$OVERLAY_NETWORK_IP:$RPC_PORT" \
    -debug=tor "$CHAIN_TEXT"
else
    echo "Error: CHAIN not set."
    exit
fi
