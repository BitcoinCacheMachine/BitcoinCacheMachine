#!/bin/bash


ELECTRUM_CMD_TXT=""
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    ELECTRUM_CMD_TXT="--testnet"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    ELECTRUM_CMD_TXT="--regtest"
fi
