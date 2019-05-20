#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

bash -c "$BCM_LXD_OPS/remove_tier.sh --tier-name=bitcoin"
