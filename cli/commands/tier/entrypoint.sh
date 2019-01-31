#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z ${BCM_CLI_VERB} ]; then
    echo "Please provide a SSH command."
    cat ./help.txt
    exit
fi

if [[ $BCM_CLI_VERB == "list" ]]; then
    echo "Actively deployed BCM tiers:"
    
    LXC_LIST_OUTPUT=$(lxc list --format csv)
    if echo $LXC_LIST_OUTPUT | grep -q "bcm-gateway"; then
        echo "bcm-gateway"
    fi
    
    if echo $LXC_LIST_OUTPUT | grep -q "bcm-kafka"; then
        echo "bcm-kafka"
    fi
    
    if echo $LXC_LIST_OUTPUT | grep -q "bcm-bitcoin"; then
        echo "bcm-bitcoin"
    fi
    
    if echo $LXC_LIST_OUTPUT | grep -q "bcm-ui"; then
        echo "bcm-ui"
    fi
    exit
fi

TIER_NAME=${3:-}
if [ -z ${TIER_NAME} ]; then
    echo "Please specify a BCM tier."
    cat ./help.txt
    exit
fi

# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
    if [[ $BCM_CLI_VERB == "create" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/up.sh --$TIER_NAME"
        
        elif [[ $BCM_CLI_VERB == "destroy" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/destroy.sh --$TIER_NAME"
    else
        cat ./help.txt
    fi
fi