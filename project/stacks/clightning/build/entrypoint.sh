#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL"

CMD_TEXT=""
BITCOIND_RPC_PORT="8332"
if [[ $CHAIN == "testnet" ]]; then
    CMD_TEXT="--testnet"
    BITCOIND_RPC_PORT="18332"
    elif [[ $CHAIN == "regtest" ]]; then
    CMD_TEXT="--regtest"
    BITCOIND_RPC_PORT="28332"
fi

wait-for-it -t 300 "bitcoindrpc-$CHAIN:$BITCOIND_RPC_PORT"
/root/lightning/lightningd/lightningd \
--conf=/root/.lightning/config \
--proxy="$TOR_PROXY" \
--addr="autotor:$TOR_CONTROL" \
--bitcoin-rpcconnect="bitcoindrpc-$CHAIN" \
--bitcoin-rpcport="$BITCOIND_RPC_PORT" \
"$CMD_TEXT"

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
