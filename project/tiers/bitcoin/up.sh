#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env

if [[ $BCM_DEPLOY_BITCOIND == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(readlink -f ./stacks/bitcoind/env)"
fi

if [[ $BCM_DEPLOY_CLIGHTNING == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(readlink -f ./stacks/clightning/env)"
fi
