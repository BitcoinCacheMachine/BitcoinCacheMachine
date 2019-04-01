#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if bcm tier list | grep -q ui; then
    echo "The 'ui' tier is already provisioned."
    exit
fi

# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q kafka; then
    bcm tier create kafka
fi

# Let's provision the system containers to the cluster.
export TIER_NAME=ui
bash -c "$BCM_LXD_OPS/create_tier.sh --tier-name=$TIER_NAME"


source ./env

# bring up the docker UI STACKS.
if [[ $BCM_DEPLOY_STACK_CONNECTUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/connectui/env --container-name=$BCM_UI_HOST_NAME"
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/schemaregistryui/env --container-name=$BCM_UI_HOST_NAME"
fi

if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkatopicsui/env --container-name=$BCM_UI_HOST_NAME"
fi

if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkacontrolcenter/env --container-name=$BCM_UI_HOST_NAME"
fi

