#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# exit if the tier already exists! Operator must first delete it.
if bcm tier list | grep -q "bitcoin-$BCM_ACTIVE_CHAIN"; then
    echo "The 'bitcoin-$BCM_ACTIVE_CHAIN' tier is already provisioned."
    exit
fi

# don't even think about proceeding unless the manager BCM tier is up and running.
if ! bcm tier list | grep -q "manager"; then
    bash -c "$BCM_GIT_DIR/project/tiers/manager/up.sh"
fi

# ensure the kafka tier is up
if ! bcm tier list | grep -q "kafka"; then
    bash -c "$BCM_GIT_DIR/project/tiers/kafka/up.sh"
fi

# ensure the underlay tier is up.
if ! bcm tier list | grep -q "underlay"; then
    bash -c "$BCM_GIT_DIR/project/tiers/underlay/up.sh"
fi

# Let's provision the system containers to the cluster.
../create_tier.sh --tier-name="bitcoin-$BCM_ACTIVE_CHAIN"
