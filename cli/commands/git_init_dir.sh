#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# if $BCM_RUNTIME_DIR/certs doesn't exist, create it
BCM_DIR=$1
if [ ! -d "$BCM_DIR" ]; then
    echo "Creating git repository at $BCM_DIR"
    mkdir -p "$BCM_DIR"
    
    if [[ -z $(git config --global --get user.name) ]]; then
        git config --global user.name "bcm"
    fi
    
    if [[ -z $(git config --global --get user.email) ]]; then
        git config --global user.name "bcm@$(hostname)"
    fi
    
    cd "$BCM_DIR"
    git init
    git config user.name "bcm"
    git config user.email "bcm@$(hostname)"
    touch debug.log
    echo "Created $BCM_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." >"$BCM_DIR/debug.log"
    git add "*"
    git commit -m "Initialized git repo."
fi