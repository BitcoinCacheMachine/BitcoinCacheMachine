#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if bcm tier list | grep -q kafka; then
    echo "The 'kafka' tier is already provisioned."
    exit
fi

# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q gateway; then
    bcm tier create gateway
fi

# Let's provision the system containers to the cluster.
export TIER_NAME=kafka
bash -c "$BCM_LXD_OPS/create_tier.sh --tier-name=$TIER_NAME"

# shellcheck disable=1091
source ./params.sh "$@"

# now it's time to deploy zookeeper. Let's deploy a zookeeper node to the first
# 5 nodes (if we have a cluster of that size). 5 should be more than enough for
# most deployments.
CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)
export CLUSTER_NODE_COUNT="$CLUSTER_NODE_COUNT"

# shellcheck disable=SC1091
source ./zookeeper/get_env.sh
bash -c "./zookeeper/up.sh"

export ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT"
export ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS"

# shellcheck disable=SC1091
source ./broker/get_env.sh
export KAFKA_BOOSTRAP_SERVERS="$KAFKA_BOOSTRAP_SERVERS"
bash -c "./broker/up_lxc_broker.sh"

if [[ $BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkaschemareg/env --container-name=$BCM_KAFKA_HOST_NAME"
fi

if [[ $BCM_DEPLOY_STACK_KAFKA_REST == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkarest/env --container-name=$BCM_KAFKA_HOST_NAME"
fi

if [[ $BCM_DEPLOY_STACK_KAFKA_CONNECT == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkaconnect/env  --container-name=$BCM_KAFKA_HOST_NAME"
fi
