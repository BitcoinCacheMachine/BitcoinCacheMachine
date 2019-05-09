#!/bin/bash

set -e

export IMAGE_NAME="bcm-bitcoin-core"

export TIER_NAME="bitcoin"
export STACK_NAME="bitcoind"
export SERVICE_NAME="bitcoind"

export STACK_DOCKER_VOLUMES="cli wallet cookie old-blocks"
export DOCKER_VOLUME_NAME="bitcoind-$BCM_ACTIVE_CHAIN""_data"

BITCOIND_RPC_PORT=8332
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    BITCOIND_RPC_PORT=18332
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    BITCOIND_RPC_PORT=28332
fi

export BITCOIND_RPC_PORT="$BITCOIND_RPC_PORT"
