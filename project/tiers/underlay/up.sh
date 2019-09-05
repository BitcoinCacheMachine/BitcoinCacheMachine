#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the manager BCM tier is up and running.
if bcm tier list | grep -q "underlay"; then
    echo "The 'underlay' tier is already provisioned."
    exit
fi

# ensure the kafka tier is deployed
BCM_LOGGING=lxd
if ! bcm tier list | grep -q "kafka"; then
    # TODO REMOVE THIS AT SOME POINT.
    if [[ $BCM_LOGGING == kafka ]]; then
        bcm tier create kafka --logging=kafka
        elif [[ $BCM_LOGGING == lxd ]]; then
        bcm tier create kafka --logging=lxd
    fi
fi

# Let's provision the system containers to the cluster.
export TIER_NAME=underlay
bash -c "$BCM_LXD_OPS/create_tier.sh --tier-name=$TIER_NAME"

# if we're in debug mode, some visual UIs will be deployed for kafka inspection
if [[ $BCM_DEBUG == 1 ]]; then
    source ./env
    
    # bring up the docker UI STACKS.
    if [[ $BCM_DEPLOY_STACK_CONNECTUI == 1 ]]; then
        bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/connectui/env --container-name=$BCM_UNDERLAY_HOST_NAME"
    fi
    
    if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI == 1 ]]; then
        bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/schemaregistryui/env --container-name=$BCM_UNDERLAY_HOST_NAME"
    fi
    
    if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI == 1 ]]; then
        bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkatopicsui/env --container-name=$BCM_UNDERLAY_HOST_NAME"
    fi
    
    if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER == 1 ]]; then
        bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkacontrolcenter/env --container-name=$BCM_UNDERLAY_HOST_NAME"
    fi
fi
