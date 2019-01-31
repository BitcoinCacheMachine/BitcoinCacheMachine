#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./params.sh "$@"

if [[ $BCM_DEPLOY_GATEWAY == 1 ]]; then
    bash -c "./gateway/up_lxc_gateway.sh --tier-name=gateway"
fi

if [[ $BCM_DEPLOY_TIER_KAFKA == 1 ]]; then
    bcm tier create kafka
fi

if [[ $BCM_DEPLOY_TIER_UI == 1 ]]; then
    bcm tier create ui
fi

if [[ $BCM_DEPLOY_TIER_BITCOIN == 1 ]]; then
    bcm tier create bitcoin
fi