#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"
source ../defaults.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if ! lxc image list | grep -q "bcm-template"; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit
fi

# let's make sure we have the dockertemplate to init from.
if ! lxc list | grep -q "bcm-host-template"; then
    echo "Error. LXC host 'bcm-host-template' doesn't exist."
    exit
fi

# create the 'bcm_kafka_profile' lxc profile
if ! lxc profile list | grep -q "bcm_kafka_profile"; then
    lxc profile create bcm_kafka_profile
fi

# apply the default kafka.yml
lxc profile edit bcm_kafka_profile < ./lxd_profiles/kafka.yml

# get all the bcm-kafka-xx containers deployed to the cluster.
bash -c "../spread_lxc_hosts.sh --hostname=kafka"

source ../get_docker_swarm_tokens.sh

echo "Running ./provision_bcm-kafka.sh"
KAFKA_HOSTNAME="bcm-kafka-01"
PRIVATE_REGISTRY="bcm-gateway-01:5010"

if [[ -z $PRIVATE_REGISTRY ]]; then
    echo "PRIVATE_REGISTRY MUST be set."
    exit
fi


KAFKA_HOSTNAME="bcm-kafka-01"
if ! lxc list | grep -q "$KAFKA_HOSTNAME"; then
    echo "'$KAFKA_HOSTNAME' does not exist. Can't provision bcm-kafka-01"
    exit
fi

lxc file push ./kafka.daemon.json $KAFKA_HOSTNAME/etc/docker/daemon.json
lxc file push ./docker_stack/zookeeper.yml bcm-gateway-01/root/stacks/zookeeper.yml

lxc start $KAFKA_HOSTNAME

../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

lxc exec $KAFKA_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:2377

lxc exec $KAFKA_HOSTNAME -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377

# if it's the first instance, let's download the kafka image from
# docker hub; then we tag and push to our local private registry
# so subsequent kafka nodes can just download from there.


REGISTRY="bcm-gateway-01:5010"
ZOOKEEPER_IMAGE="$REGISTRY/bcm-zookeeper:latest"
KAFKA_IMAGE="$REGISTRY/bcm-kafka:latest"


if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
    lxc exec $KAFKA_HOSTNAME -- docker pull zookeeper
    lxc exec $KAFKA_HOSTNAME -- docker pull confluentinc/cp-kafka

    lxc exec $KAFKA_HOSTNAME -- docker tag zookeeper "$ZOOKEEPER_IMAGE"
    lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka "$KAFKA_IMAGE"

    lxc exec $KAFKA_HOSTNAME -- docker push "$ZOOKEEPER_IMAGE"
    lxc exec $KAFKA_HOSTNAME -- docker push "$KAFKA_IMAGE"

    lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka "$PRIVATE_REGISTRY/bcm-kafka:latest"
    lxc exec $KAFKA_HOSTNAME -- docker push "$PRIVATE_REGISTRY/bcm-kafka:latest"
fi




# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    if [[ "$endpoint" != "$MASTER_NODE" ]]; then
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
# 3 nodes (if we have a cluster of that size).
CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)

ZOOKEEPER_SERVERS="server.1=zookeeper-01:2888:3888"
ZOOKEEPER_CONNECT="zookeeper-01:2181"

if [[ $CLUSTER_NODE_COUNT -ge 2 ]]; then
    ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS server.2=zookeeper-02:2888:3888"
    ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT,zookeeper-02:2181"
fi

if [[ $CLUSTER_NODE_COUNT -ge 3 ]]; then
    ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS server.3=zookeeper-03:2888:3888"
    ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT,zookeeper-03:2181"
fi

# Deploy the first zookeeper node.
./deploy_zookeeper.sh --docker-image-name=$ZOOKEEPER_IMAGE \
    --host-ending=1 \
    --target-host="bcm-kafka-01" \
    --zookeeper-servers="$ZOOKEEPER_SERVERS"

# deploy 2nd zookeeper node if we can.
if [[ $CLUSTER_NODE_COUNT -ge 2 ]]; then
    ./deploy_zookeeper.sh --docker-image-name=$ZOOKEEPER_IMAGE \
        --host-ending=2 \
        --target-host="bcm-kafka-02" \
        --zookeeper-servers="$ZOOKEEPER_SERVERS"
fi

# deploy 3rd zookeeper if we can
if [[ $CLUSTER_NODE_COUNT -ge 3 ]]; then
    ./deploy_zookeeper.sh --docker-image-name=$ZOOKEEPER_IMAGE \
        --host-ending=3 \
        --target-host="bcm-kafka-03" \
        --zookeeper-servers="$ZOOKEEPER_SERVERS"
fi

# now let's deploy kafka
lxc file push ./docker_stack/kafka.yml bcm-gateway-01/root/stacks/kafka.yml

# let's deploy a kafka node to each cluster endpoint.
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    KAFKA_HOSTNAME="bcm-kafka-$(printf %02d "$HOST_ENDING")"

    ./deploy_kafka.sh --docker-image-name="$KAFKA_IMAGE" --host-ending="$HOST_ENDING" --zookeeper-connect="$ZOOKEEPER_CONNECT" --advertised-listeners="INSIDE://broker-$(printf %02d "$HOST_ENDING"):9092,PLAINTEXT://broker-$(printf %02d "$HOST_ENDING"):9090"
done