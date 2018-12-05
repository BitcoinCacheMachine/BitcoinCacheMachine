#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./.env

if [[ $BCM_DEPLOY_BITCOIND = 1 ]]; then
    bash -c ./bitcoind/destroy.sh
fi