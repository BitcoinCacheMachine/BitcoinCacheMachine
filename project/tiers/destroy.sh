#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./params.sh "$@"

if [[ $BCM_DEPLOY_TIER_BITCOIN == 1 ]]; then
    bcm tier destroy bitcoin
fi

if [[ $BCM_DEPLOY_TIER_UI == 1 ]]; then
    bcm tier destroy ui
fi

if [[ $BCM_DEPLOY_TIER_KAFKA == 1 ]]; then
    bcm tier destroy kafka
fi

if [[ $BCM_DEPLOY_GATEWAY == 1 ]]; then
    bash -c "./gateway/destroy_lxc_gateway.sh"
fi
