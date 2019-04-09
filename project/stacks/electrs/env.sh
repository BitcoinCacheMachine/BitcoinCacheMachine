#!/bin/bash

export IMAGE_NAME="bcm-electrs"
export IMAGE_TAG="v0.5.0"
export TIER_NAME="bitcoin"
export STACK_FILE="electrs.yml"
export STACK_NAME="electrs"
export SERVICE_NAME="electrs"
MAINNET_PORT="50001"
TESTNET_PORT="60001"
REGTEST_PORT="60401"
CHAIN="$BCM_ACTIVE_CHAIN"

# mainnet is defaults
CHAIN_TEXT=""
SERVICE_PORT="$MAINNET_PORT"
if [[ "$CHAIN" == "testnet" ]]; then
    CHAIN_TEXT="--testnet"
    SERVICE_PORT="$TESTNET_PORT"
    elif [[ "$CHAIN" == "regtest" ]]; then
    CHAIN_TEXT="--regtest"
    SERVICE_PORT="$REGTEST_PORT"
fi

export SERVICE_PORT="$SERVICE_PORT"
export CHAIN_TEXT="$CHAIN_TEXT"