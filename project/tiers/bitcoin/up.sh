#!/usr/bin/env bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./.env

if [[ $BCM_DEPLOY_BITCOIND == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/bitcoind/.env
    bash -c "$BCM_GIT_DIR/project/shared/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi
