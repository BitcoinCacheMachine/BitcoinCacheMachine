#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! bcm tier list | grep -q "kafka"; then
    bcm tier create kafka --logging="$BCM_LOGGING_METHOD"
fi

# don't even think about proceeding unless the manager BCM tier is up and running.
if bcm tier list | grep -q "underlay"; then
    echo "INFO: The 'underlay' tier is already provisioned. If there is an error, it may need to be redeployed."
    exit
fi

if ! bcm tier list | grep -q "kafka"; then
    echo "ERROR: Could not find the kafka tier. Exiting"
    exit 1
fi

# Let's provision the system containers to the cluster.
export TIER_NAME=underlay
../create_tier.sh --tier-name="$TIER_NAME"

# if we're in debug mode, some visual UIs will be deployed for kafka inspection
if [[ $BCM_LOGGING_METHOD == kafka ]]; then
    source ./env
    
    for stack in connectui schemaregistryui kafkatopicsui kafkacontrolcenter; do
        bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$BCM_GIT_DIR/project/tiers/stacks/$stack/env --container-name=$BCM_UNDERLAY_HOST_NAME"
    done
fi
