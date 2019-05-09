#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if [ "$(lxc remote get-default)" != "local" ]; then
    CHAIN=$(lxc project list | grep "(current)" | awk '{print $2}')
    
    if [[ $CHAIN != "default" ]]; then
        echo "$CHAIN"
    else
        echo "$BCM_DEFAULT_CHAIN"
    fi
else
    echo "$BCM_DEFAULT_CHAIN"
fi
