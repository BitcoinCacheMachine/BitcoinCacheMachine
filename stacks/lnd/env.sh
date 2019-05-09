#!/bin/bash

# mainnet is defaults
CHAIN_TEXT=""

if [[ "$BCM_ACTIVE_CHAIN" == "testnet" ]]; then
    CHAIN_TEXT="--bitcoin.testnet"
    elif [[ "$BCM_ACTIVE_CHAIN" == "regtest" ]]; then
    CHAIN_TEXT="--bitcoin.regtest"
fi

export CHAIN_TEXT="$CHAIN_TEXT"

export IMAGE_NAME="bcm-lnd"
#export IMAGE_TAG="v0.5.2-beta"
export TIER_NAME="bitcoin"
export STACK_NAME="lnd"
export SERVICE_NAME="lnd"

export STACK_DOCKER_VOLUMES="certificate-data data log-data admin-macaroon readonly-macaroon"
