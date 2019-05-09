#!/bin/bash

set -Eeuo pipefail


if [[ -z $BCM_ACTIVE_CHAIN ]]; then
    echo "ERROR: BCM_ACTIVE_CHAIN was not passed."
    exit
fi

if [[ -z $ELECTRS_RPC_PORT ]]; then
    echo "ERROR: ELECTRS_RPC_PORT was not passed."
    exit
fi

export RUST_BACKTRACE=1

#OVERLAY_IP=$(ip addr | grep "172.16.241." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

BITCOIND_RPC_IP_PORT=
if [[ -f /root/.bitcoin/rpcip.txt ]]; then
    BITCOIND_RPC_IP_PORT=$(</root/.bitcoin/rpcip.txt)
fi

#/root/.cargo/bin/cargo run --release -- help

if [[ ! -z $BITCOIND_RPC_IP_PORT ]]; then
    cargo run --release -- -vvv --timestamp --network="$BCM_ACTIVE_CHAIN" --daemon-dir /root/.bitcoin --db-dir /root/.electrs/db --electrum-rpc-addr="0.0.0.0:$ELECTRS_RPC_PORT" --daemon-rpc-addr="$BITCOIND_RPC_IP_PORT"
fi
