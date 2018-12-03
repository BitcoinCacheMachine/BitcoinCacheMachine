#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")" 
source ./.env
source "$BCM_GIT_DIR/.env"


# shellcheck disable=SC1091
source ./.env

bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
