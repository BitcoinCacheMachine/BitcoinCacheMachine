#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")" 

BCM_DEPLOY_GATEWAY=0
BCM_DEPLOY_TIER_KAFKA=0
BCM_DEPLOY_TIER_UI=0
BCM_DEPLOY_TIER_BITCOIN=0

# shellcheck disable=SC1091
source ./.env

if [[ $BCM_DEPLOY_GATEWAY = 1 ]]; then
    bash -c "./gateway/up_lxc_gateway.sh"
fi

if [[ $BCM_DEPLOY_TIER_KAFKA = 1 ]]; then
    bash -c "./create_tier.sh --tier-name=kafka"
fi

if [[ $BCM_DEPLOY_TIER_UI = 1 ]]; then
    bash -c "./create_tier.sh --tier-name=ui"
fi

if [[ $BCM_DEPLOY_TIER_BITCOIN = 1 ]]; then
    bash -c "./create_tier.sh --tier-name=bitcoin"
fi