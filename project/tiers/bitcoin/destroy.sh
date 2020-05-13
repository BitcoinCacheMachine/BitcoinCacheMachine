#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

bash -c "$BCM_GIT_DIR/project/tiers/remove_tier.sh --tier-name=bitcoin"
