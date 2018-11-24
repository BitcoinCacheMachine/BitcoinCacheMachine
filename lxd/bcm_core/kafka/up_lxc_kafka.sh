#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"
source ../defaults.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if ! lxc image list | grep -q "bcm-template"; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
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
# and get their bcm-kafka-XX LXC host deployed
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
# 5 nodes (if we have a cluster of that size). 5 should be more than enough for
# most deployments.
CLUSTER_NODE_COUNT=$(bcm cluster list --cluster-name="$(lxc remote get-default)" --endpoints | wc -l)
ZOOKEEPER_SERVERS="server.1=zookeeper-01:2888:3888"
ZOOKEEPER_CONNECT="zookeeper-01:2181"
MAX_ZOOKEEPER_NODES=5

NODE=2
while [[ "$NODE" -le "$MAX_ZOOKEEPER_NODES" && "$NODE" -le "$CLUSTER_NODE_COUNT" ]]; do
    ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS server.$NODE=zookeeper-$(printf %02d "$NODE"):2888:3888"
    ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT,zookeeper-$(printf %02d "$NODE"):2181"
    NODE=$(( "$NODE" + 1 ))
done

echo "ZOOKEEPER_SERVERS: $ZOOKEEPER_SERVERS"
echo "ZOOKEEPER_CONNECT: $ZOOKEEPER_CONNECT"

for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    KAFKA_HOSTNAME="bcm-kafka-$(printf %02d "$HOST_ENDING")"
    ./deploy_zookeeper.sh --docker-image-name="$ZOOKEEPER_IMAGE" \
                                --host-ending="$HOST_ENDING" \
                                --target-host="$KAFKA_HOSTNAME" \
                                --zookeeper-servers="$ZOOKEEPER_SERVERS"

    if [[ $HOST_ENDING -gt $MAX_ZOOKEEPER_NODES || $HOST_ENDING -gt $CLUSTER_NODE_COUNT ]]; then
        break;
    fi
done



# now let's deploy kafka
lxc file push ./docker_stack/kafka.yml bcm-gateway-01/root/stacks/kafka.yml

if ! lxc exec bcm-gateway-01 -- docker network list | grep "kafkanet" | grep "overlay" | grep -q "swarm"; then
    lxc exec bcm-gateway-01 -- docker network create --driver=overlay --opt=encrypted --attachable=true kafkanet

    # let's deploy a kafka node to each cluster endpoint.
    for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
        HOST_ENDING=$(echo "$endpoint" | tail -c 2)
        KAFKA_HOSTNAME="bcm-kafka-$(printf %02d "$HOST_ENDING")"
        BROKER_HOSTNAME="broker-$(printf %02d "$HOST_ENDING")"
        KAFKA_ADVERTISED_LISTENERS="INSIDE://$BROKER_HOSTNAME:9092,PLAINTEXT://$BROKER_HOSTNAME:9090"

        lxc exec bcm-gateway-01 -- env DOCKER_IMAGE=$KAFKA_IMAGE BROKER_ALIAS="$BROKER_HOSTNAME" KAFKA_BROKER_ID="$HOST_ENDING" KAFKA_ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" KAFKA_ADVERTISED_LISTENERS="$KAFKA_ADVERTISED_LISTENERS" TARGET_HOST="$TARGET_HOST" docker stack deploy -c /root/stacks/kafka.yml "$BROKER_HOSTNAME"
    done
fi






    




# SCHEMA_REGISTRY_IMAGE="$REGISTRY/bcm-schema-registry:latest"
# KAFKA_HOSTNAME="bcm-kafka-01"

# if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
#     lxc exec $KAFKA_HOSTNAME -- docker pull confluentinc/cp-schema-registry:5.0.1
#     lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-schema-registry:5.0.1 "$SCHEMA_REGISTRY_IMAGE"
#     lxc exec $KAFKA_HOSTNAME -- docker push "$SCHEMA_REGISTRY_IMAGE"
# fi


# # now let's deploy kafka
# lxc file push ./docker_stack/schema-registry.yml bcm-gateway-01/root/stacks/schema-registry.yml

# lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$SCHEMA_REGISTRY_IMAGE" KAFKA_ZOOKEEPER_CONNECT="$ZOOKEEPER_CONNECT" docker stack deploy -c /root/stacks/schema-registry.yml schemaregistry







# KAFKA_REST_IMAGE="$REGISTRY/bcm-kafka-rest:latest"
# if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
#     lxc exec $KAFKA_HOSTNAME -- docker pull confluentinc/cp-kafka-rest:5.0.1
#     lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka-rest:5.0.1 "$KAFKA_REST_IMAGE"
#     lxc exec $KAFKA_HOSTNAME -- docker push "$KAFKA_REST_IMAGE"
# fi


# #

