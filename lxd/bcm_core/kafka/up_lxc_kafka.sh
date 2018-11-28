#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# create the 'bcm_kafka_profile' lxc profile
if ! lxc profile list | grep -q "bcm_kafka_profile"; then
    lxc profile create bcm_kafka_profile
fi

# apply the default kafka.yml
lxc profile edit bcm_kafka_profile < ./lxd_profiles/kafka.yml

# get all the bcm-kafka-xx containers deployed to the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --hostname=kafka"

# shellcheck disable=SC1090
source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"

echo "Running ./provision_bcm-kafka.sh"
export KAFKA_HOSTNAME="bcm-kafka-01"

if ! lxc list | grep -q "$KAFKA_HOSTNAME"; then
    echo "'$KAFKA_HOSTNAME' does not exist. Can't provision bcm-kafka-01"
    exit
fi

lxc file push ./kafka.daemon.json $KAFKA_HOSTNAME/etc/docker/daemon.json

lxc start $KAFKA_HOSTNAME

../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

lxc exec $KAFKA_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:2377

lxc exec $KAFKA_HOSTNAME -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377

# let's cycle through the other cluster members (other than the master)
# and get their bcm-kafka-XX LXC host deployed
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    if [[ "$endpoint" != "$KAFKA_HOSTNAME" ]]; then
        HOST_ENDING=$(echo "$endpoint" | tail -c 2)
        KAFKA_HOSTNAME="bcm-kafka-$(printf %02d "$HOST_ENDING")"

        if [[ "$HOST_ENDING" -ge 2 ]]; then
            lxc file push ./kafka.daemon.json "$KAFKA_HOSTNAME/etc/docker/daemon.json"

            lxc start "$KAFKA_HOSTNAME"

            ../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

            # make sure gateway and kafka hosts can reach the swarm master.
            # this steps helps resolve networking before we issue any meaningful
            # commands.
            lxc exec "$KAFKA_HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:2377
            lxc exec "$KAFKA_HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:5000
            lxc exec "$KAFKA_HOSTNAME" -- wait-for-it -t 0 bcm-gateway-02:5001

            # All other LXD bcm-kafka nodes are workers.
            lxc exec "$KAFKA_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
        fi
    fi
done


# now it's time to deploy zookeeper. Let's deploy a zookeeper node to the first
# 5 nodes (if we have a cluster of that size). 5 should be more than enough for
# most deployments.
CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)
export CLUSTER_NODE_COUNT=$CLUSTER_NODE_COUNT

source ./zookeeper/get_env.sh
bash -c ./zookeeper/up_lxc_zookeeper.sh

export ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT"
export ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS"

source ./broker/get_env.sh
export KAFKA_BOOSTRAP_SERVERS=$KAFKA_BOOSTRAP_SERVERS
bash -c "./broker/up_lxc_broker.sh"

./schemareg/up_schema-registry.sh
./rest/up_kafka-rest.sh
./connect/up_kafka-connect.sh