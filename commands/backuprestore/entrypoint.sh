#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ -n "${VALUE}" ]; then
    STACK_NAME="$2"
else
    echo "Please provide a backup command."
    cat ./help.txt
    exit
fi

LXC_HOST="$BCM_BITCOIN_HOST_NAME"
