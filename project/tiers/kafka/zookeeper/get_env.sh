#!/bin/bash

set -Eeuo pipefail


CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)
ZOOKEEPER_SERVERS="server.1=zookeeper-01:2888:3888"
ZOOKEEPER_CONNECT="zookeeper-01:2181"
export MAX_ZOOKEEPER_NODES=5

NODE=2
while [[ "$NODE" -le "$MAX_ZOOKEEPER_NODES" && "$NODE" -le "$CLUSTER_NODE_COUNT" ]]; do
    ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS server.$NODE=zookeeper-$(printf %02d "$NODE"):2888:3888"
    ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT,zookeeper-$(printf %02d "$NODE"):2181"
    NODE=$(( "$NODE" + 1 ))
done

export ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS"
export ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT"