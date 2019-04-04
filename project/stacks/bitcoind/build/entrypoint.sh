#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh --host-ending="$LXC_HOSTNAME"

if [[ -z "$TOR_PROXY" ]]; then
    echo "ERROR:  TOR_PROXY could not be determined."
    exi
fi
wait-for-it -t 10 "$TOR_PROXY"

if [[ -z "$TOR_CONTROL" ]]; then
    echo "ERROR:  TOR_CONTROL could not be determined."
    exit
fi
wait-for-it -t 10 "$TOR_CONTROL"

if [[ ! -z "$CHAIN" ]]; then
    # these are defaults are for mainnet.
    GOGO_FILE=/root/.bitcoin/gogo
    CHAIN_TEXT=""
    
    if [[ "$CHAIN" == "testnet" ]]; then
        GOGO_FILE=/root/.bitcoin/testnet3/gogo
        CHAIN_TEXT="-testnet"
        elif [[ "$CHAIN" == "mainnet" ]]; then
        GOGO_FILE=/root/.bitcoin/gogo
        elif [[ "$CHAIN" == "regtest" ]]; then
        GOGO_FILE=/root/.bitcoin/regtest/gogo
        CHAIN_TEXT="-regtest"
    else
        echo "Error: CHAIN must be either 'testnet', 'mainnet', or 'regtest'."
        exit
    fi
    
    # wait for the managementt plane.
    bash -c "/bcm/wait_for_gogo.sh --gogofile=$GOGO_FILE"
    bitcoind -conf=/root/.bitcoin/bitcoin.conf \
    -datadir=/root/.bitcoin \
    -proxy="$TOR_PROXY" \
    -torcontrol="$TOR_CONTROL" \
    -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" \
    -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" \
    -debug=tor "$CHAIN_TEXT"
    
else
    echo "Error: CHAIN not set."
    exit
fi
