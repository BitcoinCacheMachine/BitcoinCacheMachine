#!/bin/bash

set -Eeu

source /bcm/proxy_ip_determinant.sh

if [[ -z "$TOR_PROXY" ]]; then
    echo "ERROR:  TOR_PROXY could not be determined."
    exit
else
    wait-for-it -t 10 "$TOR_PROXY"
fi

if [[ -z "$TOR_CONTROL_HOST" ]]; then
    echo "ERROR:  TOR_CONTROL_HOST could not be determined."
    exit
else
    wait-for-it -t 10 "$TOR_CONTROL_HOST"
fi

if [[ ! -z "$CHAIN" ]]; then
    GOGO_FILE=
    if [[ "$CHAIN" == "testnet" ]]; then
        GOGO_FILE=/data/testnet3/gogogo
        elif [[ "$CHAIN" == "mainnet" ]]; then
        GOGO_FILE=/data/gogogo
    else
        echo "Error: CHAIN must be either 'testnet' or 'mainnet'."
        exit
    fi
    
    # wait for the managementt plane.
    bash -c "/bcm/wait_for_gogo.sh $GOGO_FILE"
else
    echo "Error: CHAIN not set."
    exit
fi

if [[ "$CHAIN" == "testnet" ]]; then
    bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor -testnet
    elif [[ "$CHAIN" == "mainnet" ]]; then
    bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor
fi