#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q gateway; then
    bcm tier create gateway
fi

bash -c "$BCM_GIT_DIR/project/shared/remove_tier.sh --tier-name=bitcoin"
