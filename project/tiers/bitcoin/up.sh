#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

bash -c "$BCM_GIT_DIR/project/tiers/up.sh --ui"