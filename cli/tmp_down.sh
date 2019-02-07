#!/bin/bash

set -Eeuo pipefail

source "$BCM_GIT_DIR/env"

encfs -u "$BCM_TEMP_DIR">>/dev/null

if [[ -d "$BCM_TEMP_DIR" ]]; then
    rm -rf "$BCM_TEMP_DIR"
fi

if [[ -d "$BCM_TEMP_DIR""_enc" ]]; then
    rm -rf "$BCM_TEMP_DIR""_enc"
fi
