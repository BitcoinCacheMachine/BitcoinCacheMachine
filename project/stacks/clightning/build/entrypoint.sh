#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL"

CMD_TEXT=""
if [[ $CHAIN == "testnet" ]]; then
    CMD_TEXT="--testnet"
    elif [[ $CHAIN == "regtest" ]]; then
    CMD_TEXT="--regtest"
fi

if [[ -z $BITCOIND_RPC_PORT ]]; then
    echo "ERROR: BITCOIND_RPC_PORT not supplied. Exiting."
    exit
fi

wait-for-it -t 300 "bitcoindrpc-$CHAIN:$BITCOIND_RPC_PORT"
/root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL" --rpcbind="$OVERLAY_NETWORK_IP" "$CMD_TEXT"

#
#-proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332"
#/root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL"
#--proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL"

#--tor-service-password=password --log-level=debug
# elif [[ $CHAIN == "mainnet" ]]; then
# /root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL" --tor-service-password=password --log-level=debug
