#!/bin/bash

export IMAGE_NAME="bcm-electrs"
export TIER_NAME="bitcoin$BCM_ACTIVE_CHAIN"
export STACK_NAME="electrs"
export SERVICE_NAME="electrs"
export STACK_DOCKER_VOLUMES="data"

ELECTRS_RPC_PORT=50001
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    ELECTRS_RPC_PORT=60001
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    ELECTRS_RPC_PORT=60401
fi

export ELECTRS_RPC_PORT="$ELECTRS_RPC_PORT"
export STACK_DOCKER_VOLUMES="data"
