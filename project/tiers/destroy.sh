#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")" 

# shellcheck disable=SC1091
source ./.env

if [[ $BCM_DEPLOY_TIER_BITCOIN = 1 ]]; then
    bash -c "./remove_tier.sh --tier-name=bitcoin"
fi

if [[ $BCM_DEPLOY_TIER_UI = 1 ]]; then
    bash -c "./remove_tier.sh --tier-name=ui"
fi

if [[ $BCM_DEPLOY_TIER_KAFKA = 1 ]]; then
    bash -c "./remove_tier.sh --tier-name=kafka"
fi

if [[ $BCM_DEPLOY_GATEWAY = 1 ]]; then
    bash -c "./gateway/destroy_lxc_gateway.sh"
fi