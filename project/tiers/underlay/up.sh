#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# let's make sure the kafka tier exists before we deploy underlay
if ! lxc list --format csv --columns ns | grep "RUNNING" | grep -q "bcm-kafka"; then
    bash -c "$BCM_GIT_DIR/project/tiers/kafka/up.sh"
fi

# Let's provision the system containers to the cluster.
export TIER_NAME=underlay
../create_tier.sh --tier-name="$TIER_NAME"

source ./env

UNDERLAY_STACKS_DIR="$BCM_GIT_DIR/project/tiers/underlay/stacks"
for stack in connectui schemaregistryui kafkatopicsui kafkacontrolcenter; do
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$UNDERLAY_STACKS_DIR/$stack/env --container-name=$BCM_UNDERLAY_HOST_NAME"
done
