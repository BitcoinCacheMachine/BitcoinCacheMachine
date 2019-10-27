#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# let's make sure the underlay tier exists before we deploy bitcoin
if ! lxc list --format csv --columns ns | grep "RUNNING" | grep -q "bcm-underlay"; then
    bash -c "$BCM_GIT_DIR/project/tiers/underlay/up.sh"
fi

# deploy the bitcoin tier if it doesn't already exist.
if lxc list --format csv --columns ns | grep "RUNNING" | grep -q "bcm-bitcoin-$BCM_ACTIVE_CHAIN"; then
    # Let's provision the system containers to the cluster.
    ../create_tier.sh --tier-name="bitcoin-$BCM_ACTIVE_CHAIN"
fi