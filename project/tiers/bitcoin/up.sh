#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if bcm tier list | grep -q "bitcoin$BCM_ACTIVE_CHAIN"; then
    echo "The 'bitcoin$BCM_ACTIVE_CHAIN' tier is already provisioned."
    exit
fi

# don't even think about proceeding unless the gateway BCM tier is up and running.
if bcm tier list | grep -q "underlay"; then
    bcm tier create underlay
fi

# Let's provision the system containers to the cluster.
bash -c "$BCM_LXD_OPS/create_tier.sh --tier-name=bitcoin$BCM_ACTIVE_CHAIN"
