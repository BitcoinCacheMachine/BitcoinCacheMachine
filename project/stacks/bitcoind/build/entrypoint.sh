#!/bin/bash

set -Eeuo pipefail

# shellcheck disable=SC1091
source /bcm/proxy_ip_determinant.sh --host-ending="$HOST_ENDING"

if [[ -z "$TOR_PROXY" ]]; then
    echo "ERROR:  TOR_PROXY could not be determined."
    exi
fi
wait-for-it -t 10 "$TOR_PROXY"

if [[ -z "$TOR_CONTROL_HOST" ]]; then
    echo "ERROR:  TOR_CONTROL_HOST could not be determined."
    exit
fi
wait-for-it -t 10 "$TOR_CONTROL_HOST"

if [[ ! -z "$CHAIN" ]]; then
    GOGO_FILE=
    if [[ "$CHAIN" == "testnet" ]]; then
        GOGO_FILE=/root/.bitcoin/testnet3/gogo
        elif [[ "$CHAIN" == "mainnet" ]]; then
        GOGO_FILE=/root/.bitcoin/gogo
        elif [[ "$CHAIN" == "regtest" ]]; then
        GOGO_FILE=/root/.bitcoin/regtest/gogo
    else
        echo "Error: CHAIN must be either 'testnet', 'mainnet', or 'regtest'."
        exit
    fi
    
    # wait for the managementt plane.
    bash -c "/bcm/wait_for_gogo.sh --gogofile=$GOGO_FILE"
    
    if [[ "$CHAIN" == "testnet" ]]; then
        bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor -testnet
        elif [[ "$CHAIN" == "mainnet" ]]; then
        bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor
    fi
else
    echo "Error: CHAIN not set."
    exit
fi
