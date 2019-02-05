#!/bin/bash

set -Eeuo

export GOGO_FILE=
if [[ "$CHAIN" == "testnet" ]]; then
    GOGO_FILE=/data/testnet3/gogogo
    elif [[ $CHAIN == "mainnet" ]]; then
    GOGO_FILE=/data/gogogo
else
    echo "Error: CHAIN must be either 'testnet' or 'mainnet'."
    exit
fi

export GOGO_FILE="$GOGO_FILE"