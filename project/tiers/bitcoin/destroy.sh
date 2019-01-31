#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# shellcheck disable=SC1091
source ./env

if [[ $BCM_DEPLOY_BITCOIND == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --env-file-path=$(readlink -f ./stacks/bitcoind/.env)"
fi