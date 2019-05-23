#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z "${BCM_CLI_VERB}" ]; then
    cat ./help.txt
    exit
fi

# make sure the user has sent in a valid command; quit if not.
if [[ $BCM_CLI_VERB != "list" && $BCM_CLI_VERB != "create" && $BCM_CLI_VERB != "destroy" && $BCM_CLI_VERB != "clear" ]]; then
    echo "Error: invalid 'bcm tier' command"
    exit
fi

# if the current cluster is not configured, let's bring it into existence.
if [[ $(lxc remote get-default) == "local" ]]; then
    bcm cluster create
fi

if [[ $BCM_CLI_VERB == "list" ]]; then
    LXC_LIST_OUTPUT=$(lxc list --format csv --columns ns | grep "RUNNING")
    if echo "$LXC_LIST_OUTPUT" | grep -q "bcm-manager"; then
        echo "manager"
    fi
    
    if echo "$LXC_LIST_OUTPUT" | grep -q "bcm-kafka"; then
        echo "kafka"
    fi
    
    if echo "$LXC_LIST_OUTPUT" | grep -q "bcm-underlay"; then
        echo "underlay"
    fi
    
    if echo "$LXC_LIST_OUTPUT" | grep -q "bcm-bitcoin$BCM_ACTIVE_CHAIN"; then
        echo "bitcoin$BCM_ACTIVE_CHAIN"
    fi
    
    exit
fi

if [[ "$BCM_CLI_VERB" == "clear" ]]; then
    bcm tier destroy bitcoin
    bcm tier destroy underlay
    bcm tier destroy kafka
    bcm tier destroy manager
    bash -c "$BCM_PROJECT_DIR/destroy.sh"
    
    exit
fi

TIER_NAME=${3:-}
if [ -z "${TIER_NAME}" ]; then
    echo "Please specify a BCM tier."
    cat ./help.txt
    exit
fi



if [[ $BCM_CLI_VERB == "create" ]]; then
    if [[ $TIER_NAME == "manager" ]]; then
        # let's make sure we have the LXD project set up correctly.
        bash -c "$BCM_GIT_DIR/project/tiers/manager/up.sh"
    fi
    
    if [[ $TIER_NAME == "kafka" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/kafka/up.sh"
    fi
    
    if [[ $TIER_NAME == "underlay" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/underlay/up.sh"
    fi
    
    if  [[ $TIER_NAME == "bitcoin" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/bitcoin/up.sh"
    fi
fi

if [[ $BCM_CLI_VERB == "destroy" ]]; then
    if [[ $TIER_NAME == "manager" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/manager/destroy.sh"
        elif [[ $TIER_NAME == "kafka" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/kafka/destroy.sh"
        elif [[ $TIER_NAME == "underlay" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/underlay/destroy.sh"
        elif  [[ $TIER_NAME == "bitcoin" ]]; then
        bash -c "$BCM_LXD_OPS/remove_tier.sh --tier-name=bitcoin"
    fi
fi

if [[ $BCM_CLI_VERB != "list" && $BCM_CLI_VERB != "destroy" && $BCM_CLI_VERB != "create" ]]; then
    echo "Error: next command should be 'create', 'remove', or 'list'."
    cat ./help.txt
fi
