#!/bin/bash

set -Eeuo pipefail

encfs -u "$BCM_TEMP_DIR">>/dev/null

if [[ -d "$BCM_TEMP_DIR" ]]; then
    echo "Removing $BCM_TEMP_DIR"
    rm -rf "$BCM_TEMP_DIR"
fi

if [[ -d "$BCM_TEMP_DIR""_enc" ]]; then
    echo "Removing $BCM_TEMP_DIR""_enc"
    rm -rf "$BCM_TEMP_DIR""_enc"
fi
