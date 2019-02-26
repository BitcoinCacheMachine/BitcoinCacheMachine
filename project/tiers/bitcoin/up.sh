#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./user_prompt.sh

if [[ $DEPLOY_TESTNET == 1 ]]; then
    bcm stack deploy bitcoind --chain=testnet
    ./file_upload.sh --chain=testnet --blocks="$UPLOAD_TESTNET_BLOCKS" --chainstate="$UPLOAD_TESTNET_CHAINSTATE"
fi

if [[ $DEPLOY_MAINNET == 1 ]]; then
    bcm stack deploy bitcoind --chain=mainnet
    ./file_upload.sh --chain=mainnet --blocks="$UPLOAD_MAINNET_BLOCKS" --chainstate="$UPLOAD_MAINNET_CHAINSTATE"
fi
