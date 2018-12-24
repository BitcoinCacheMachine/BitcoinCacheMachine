#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# if $BCM_RUNTIME_DIR/certs doesn't exist, create it
BCM_DIR=$1
if [ ! -d "$BCM_DIR" ]; then
    echo "Creating git repository at $BCM_DIR"
    mkdir -p "$BCM_DIR"
    
    git init "$BCM_DIR/"
    
    git config user.name "bcm"
    git config user.email "bcm@$(hostname)"
    
    echo "Created $BCM_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." >"$BCM_DIR/debug.log"
fi
