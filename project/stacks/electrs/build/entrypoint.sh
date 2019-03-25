#!/bin/bash

set -Eeuox pipefail

echo "entrypoint for electrs"

echo "PWD: $(pwd)"

# 50001 for mainnet
ELECTRUM_RPC="0.0.0.0:50001"
BITCOIND_RPC_ADDR="bitcoindrpc-$CHAIN:8332"
if [[ "$CHAIN" == "testnet" ]]; then
    ELECTRUM_RPC="0.0.0.0:60001"
    BITCOIND_RPC_ADDR="bitcoindrpc-$CHAIN:18332"
    elif [[ "$CHAIN" == "regtest" ]]; then
    ELECTRUM_RPC="0.0.0.0:60401"
    BITCOIND_RPC_ADDR="bitcoindrpc-$CHAIN:18443"
fi


#cargo run --release -- -vvv --timestamp --db-dir /root/.electrs/db
cargo run --release --bin electrs -- -vvvv --daemon-dir /root/.bitcoin --electrum-rpc-addr="$ELECTRUM_RPC" --network="$CHAIN" --daemon-rpc-addr="$BITCOIND_RPC_ADDR"