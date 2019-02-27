#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./params.sh "$@"

if [[ $BCM_DEPLOY_TIER_BITCOIN == 1 ]]; then
    bash -c "./remove_tier.sh --tier-name=bitcoin"
fi

if [[ $BCM_DEPLOY_TIER_UI == 1 ]]; then
    bash -c "./remove_tier.sh --tier-name=ui"
fi

if [[ $BCM_DEPLOY_TIER_KAFKA == 1 ]]; then
    if ! bcm tier list | grep -q "ui"; then
        bash -c "./remove_tier.sh --tier-name=kafka"
    else
        echo "ERROR: Can't remove BCM Tier 'kafka' due to dependent tier 'ui'."
    fi
fi

if [[ $BCM_DEPLOY_GATEWAY == 1 ]]; then
    CAN_DELETE=1
    
    if bcm tier list | grep -q "ui"; then
        CAN_DELETE=0
    fi
    
    if bcm tier list | grep -q "kafka"; then
        CAN_DELETE=0
    fi
    
    if bcm tier list | grep -q "bitcoin"; then
        CAN_DELETE=0
    fi
    
    if [[ "$CAN_DELETE" == 1 ]]; then
        bash -c "./gateway/destroy.sh"
    else
        echo "ERROR: Can't remove BCM Tier 'gateway' due to dependent tier."
    fi
fi