#!/bin/bash

set -Eeuo pipefail

encfs -u /tmp/bcm>>/dev/null

if [[ -d /tmp/bcm ]]; then
    rm -rf /tmp/bcm
fi

if [[ -d /tmp/bcm_enc ]]; then
    rm -rf /tmp/bcm_enc
fi
