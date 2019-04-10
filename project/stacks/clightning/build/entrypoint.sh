#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL"

if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    CHAIN_TEXT="-$CHAIN_TEXT"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    CHAIN_TEXT="-$CHAIN_TEXT"
fi

wait-for-it -t 300 "bitcoindrpc-$BCM_ACTIVE_CHAIN:$BITCOIND_RPC_PORT"

/root/lightning/lightningd/lightningd \
--conf=/root/.lightning/config \
--proxy="$TOR_PROXY" \
--addr="autotor:$TOR_CONTROL" \
--bitcoin-rpcconnect="bitcoindrpc-$BCM_ACTIVE_CHAIN" \
--bitcoin-rpcport="$BITCOIND_RPC_PORT" \
"$CHAIN_TEXT"

# --rpcbind="$OVERLAY_NETWORK_IP" \
# --bitcoin-rpcconnect <arg>           bitcoind RPC host to connect to
# --bitcoin-rpcport <arg>
#
#-proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332"
#/root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL"
#--proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL"

#--tor-service-password=password --log-level=debug
# elif [[ $CHAIN == "mainnet" ]]; then
# /root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL" --tor-service-password=password --log-level=debug
