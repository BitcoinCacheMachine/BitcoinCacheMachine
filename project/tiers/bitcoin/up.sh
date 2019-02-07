#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source "$BCM_GIT_DIR/env"

# shellcheck source=user_prompt.sh
source ./user_prompt.sh

if [[ $DEPLOY_TESTNET == 1 ]]; then
    ./bitcoind_stack_deploy.sh --chain=testnet
    ./file_upload.sh --chain=testnet --blocks="$UPLOAD_TESTNET_BLOCKS" --chainstate="$UPLOAD_TESTNET_CHAINSTATE"
fi

if [[ $DEPLOY_MAINNET == 1 ]]; then
    ./bitcoind_stack_deploy.sh --chain=mainnet
    ./file_upload.sh --chain=mainnet --blocks="$UPLOAD_MAINNET_BLOCKS" --chainstate="$UPLOAD_MAINNET_CHAINSTATE"
fi

source ./env
