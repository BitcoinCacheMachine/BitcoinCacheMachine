#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"


# now it's time to deploy zookeeper. Let's deploy a zookeeper node to the first
# 5 nodes (if we have a cluster of that size). 5 should be more than enough for
# most deployments.
CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)
export CLUSTER_NODE_COUNT=$CLUSTER_NODE_COUNT

# shellcheck disable=SC1091
source ./zookeeper/get_env.sh
bash -c "./zookeeper/up_lxc_zookeeper.sh"

export ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT"
export ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS"


# shellcheck disable=SC1091
source ./broker/get_env.sh
export KAFKA_BOOSTRAP_SERVERS=$KAFKA_BOOSTRAP_SERVERS
bash -c "./broker/up_lxc_broker.sh"

bash -c "./stacks/schemareg/up_schema-registry.sh"
bash -c "./stacks/rest/up_kafka-rest.sh"
bash -c "./stacks/connect/up_kafka-connect.sh"