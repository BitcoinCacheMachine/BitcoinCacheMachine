#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

echo "/tiers/bitcoin/bitcoind/up.sh"

bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(readlink -f ./.env)"