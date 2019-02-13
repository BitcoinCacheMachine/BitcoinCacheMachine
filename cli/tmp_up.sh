#!/bin/bash

set -Eeuo pipefail

mkdir -p "$BCM_TEMP_DIR""_enc"
mkdir -p "$BCM_TEMP_DIR"

encfs "$BCM_TEMP_DIR""_enc" "$BCM_TEMP_DIR" -i=10 --extpass="apg -n 1 -m 30 -M CN" >> /dev/null
