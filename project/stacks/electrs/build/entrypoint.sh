#!/bin/bash

set -Eeuo pipefail

#cargo run --release -- -vvv --timestamp
cargo run --release --bin electrs -- -vvvv --daemon-dir /root/.bitcoin --electrum-rpc-addr="$ELECTRS_RPC_IP:$ELECTRS_RPC_PORT" --network="$BCM_ACTIVE_CHAIN" --daemon-rpc-addr="bitcoindrpc-$BCM_ACTIVE_CHAIN:$BITCOIND_RPC_PORT" --db-dir /root/.electrs/db
