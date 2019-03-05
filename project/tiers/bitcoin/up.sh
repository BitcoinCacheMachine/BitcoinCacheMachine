#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q kafka; then
    bcm tier create kafka
fi

bash -c "$BCM_GIT_DIR/project/tiers/up.sh --ui"
