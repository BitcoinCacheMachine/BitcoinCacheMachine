#!/bin/bash

set -Eeu

# torsocks is the network alias for the tor SOCKS proxy on the docker overlay network.
TOR_HOST_IP="$(getent hosts torsocks | awk '{ print $1 }')"
TOR_PROXY="$TOR_HOST_IP:9050"
TOR_CONTROL="$TOR_HOST_IP:9051"


wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL"

CHAIN_TEXT=
BITCOIND_RPC_PORT=8332
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    CHAIN_TEXT="--network=testnet"
    BITCOIND_RPC_PORT=18332
    # CHAIN_SUFFIX="/testnet3"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    CHAIN_TEXT="--network=regtest"
    BITCOIND_RPC_PORT=28332
    #CHAIN_SUFFIX="/regtest"
fi

wait-for-it -t 300 "bitcoindrpc-$BCM_ACTIVE_CHAIN:$BITCOIND_RPC_PORT"

/root/lightning/lightningd/lightningd --conf=/root/.lightning/config \
--lightning-dir=/root/.lightning \
--proxy="$TOR_PROXY" \
--addr="autotor:$TOR_CONTROL" \
--bitcoin-rpcconnect="bitcoindrpc-$BCM_ACTIVE_CHAIN" \
--bitcoin-rpcport="$BITCOIND_RPC_PORT" \
--bitcoin-datadir="/root/.bitcoin" \
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
