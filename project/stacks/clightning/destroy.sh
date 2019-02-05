#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# shellcheck disable=SC1091
source ./env

bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=clightning-testnet"
bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=clightning-mainnet"
