#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")" 
source ./.env
source "$BCM_GIT_DIR/.env"

bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(readlink -f ./.env)"