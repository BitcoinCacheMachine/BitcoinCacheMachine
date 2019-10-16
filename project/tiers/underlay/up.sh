#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the manager BCM tier is up and running.
if ! bcm tier list | grep -q "manager"; then
    bcm tier create manager
fi

# ensure the kafka tier is up
if ! bcm tier list | grep -q "kafka"; then
    bcm tier create kafka
fi

# ensure the underlay tier is up.
if bcm tier list | grep -q "underlay"; then
    echo "INFO: The 'underlay' tier is already provisioned. If there is an error, it may need to be redeployed."
    exit
fi


# Let's provision the system containers to the cluster.
export TIER_NAME=underlay
../create_tier.sh --tier-name="$TIER_NAME"

source ./env

for stack in connectui schemaregistryui kafkatopicsui kafkacontrolcenter; do
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$BCM_GIT_DIR/project/tiers/stacks/$stack/env --container-name=$BCM_UNDERLAY_HOST_NAME"
done
