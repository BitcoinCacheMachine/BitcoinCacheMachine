#!/bin/bash

set -eux

if [[ -z $BCM_ACTIVE_CHAIN ]]; then
    echo "ERROR: BCM_ACTIVE_CHAIN was not passed."
    exit
fi

if [[ -z $BITCOIND_RPC_PORT ]]; then
    echo "ERROR: BITCOIND_RPC_PORT was not passed."
    exit
fi

if [[ -z $ELECTRS_RPC_PORT ]]; then
    echo "ERROR: ELECTRS_RPC_PORT was not passed."
    exit
fi

export RUST_BACKTRACE=1

#cargo run --release -- -vvv --timestamp
#cargo run --release --bin electrs -- -vvv --timestamp --db-dir /root/.electrs/db --daemon-dir /root/.bitcoin --electrum-rpc-addr="0.0.0.0:$ELECTRS_RPC_PORT" --network="$BCM_ACTIVE_CHAIN" --daemon-rpc-addr="bitcoindrpc-$BCM_ACTIVE_CHAIN:$BITCOIND_RPC_PORT"
cargo run --release --bin electrs -- -vvvv --timestamp --db-dir /root/.electrs/db --daemon-dir /root/.bitcoin --electrum-rpc-addr="0.0.0.0:$ELECTRS_RPC_PORT" --network="$BCM_ACTIVE_CHAIN" --daemon-rpc-addr="bitcoindrpc-$BCM_ACTIVE_CHAIN:$BITCOIND_RPC_PORT"
