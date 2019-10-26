#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the manager BCM tier is up and running.
if ! bcm tier list | grep -q "manager"; then
    bcm tier create manager
fi

# let's get some shared (between up/down scripts).
source ./env

# Let's provision the system containers to the cluster.
export TIER_NAME=kafka
../create_tier.sh --tier-name="$TIER_NAME"

# now it's time to deploy zookeeper. Let's deploy a zookeeper node to the first
# 5 nodes (if we have a cluster of that size). 5 should be more than enough for
# most deployments.
source ./zookeeper/get_env.sh
bash -c "./zookeeper/up.sh"

export ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT"
export ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS"


source ./broker/get_env.sh
export KAFKA_BOOSTRAP_SERVERS="$KAFKA_BOOSTRAP_SERVERS"
bash -c "./broker/up_lxc_broker.sh"

KAFKA_STACKS_DIR="$BCM_GIT_DIR/project/tiers/kafka/stacks"

for stack in kafkaschemareg kafkarest kafkaconnect; do
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$KAFKA_STACKS_DIR/$stack/env --container-name=$BCM_KAFKA_HOST_NAME"
done
