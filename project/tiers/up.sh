#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")" 

source ./.env

if [[ $BCM_DEPLOY_GATEWAY = 1 ]]; then
    bash -c "./gateway/up_lxc_gateway.sh"
fi

if [[ $BCM_DEPLOY_TIER_KAFKA = 1 ]]; then
    bash -c "./create_tier.sh --tier-name=kafka"
fi

# if [[ $BCM_DEPLOY_TIER_UI_DMZ = 1 ]]; then
#     bash -c "./create_tier.sh --tier-name=ui"
# fi