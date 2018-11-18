
#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ../defaults.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit
fi


# let's make sure we have the dockertemplate to init from.
if [[ -z $(lxc list | grep "bcm-host-template") ]]; then
    echo "Error. LXC host 'bcm-host-template' doesn't exist."
    exit
fi

# create the 'bcm_kafka_profile' lxc profile
if [[ -z $(lxc profile list | grep "bcm_kafka_profile") ]]; then
    lxc profile create bcm_kafka_profile
fi

cat ./lxd_profiles/kafka.yml | lxc profile edit bcm_kafka_profile


# get all the bcm-gateway-xx containers deployed to the cluster.
bash -c "../spread_lxc_hosts.sh --hostname=kafka"

source ../get_docker_swarm_tokens.sh
DOCKER_SWARM_MANAGER_JOIN_TOKEN=$DOCKER_SWARM_MANAGER_JOIN_TOKEN
DOCKER_SWARM_WORKER_JOIN_TOKEN=$DOCKER_SWARM_WORKER_JOIN_TOKEN

echo "Running ./provision_bcm-kafka.sh"
KAFKA_HOSTNAME="bcm-kafka-01"
PRIVATE_REGISTRY="bcm-gateway-01:5010"

if [[ -z $PRIVATE_REGISTRY ]]; then
    echo "PRIVATE_REGISTRY MUST be set."
    exit
fi


KAFKA_HOSTNAME="bcm-kafka-01"
if [[ -z $(lxc list | grep "$KAFKA_HOSTNAME") ]]; then
    echo "'$KAFKA_HOSTNAME' does not exist. Can't provision bcm-kafka-01"
    exit
fi

lxc file push ./kafka.daemon.json $KAFKA_HOSTNAME/etc/docker/daemon.json
lxc file push ./docker_stack/zookeeper.yml bcm-gateway-01/root/stacks/zookeeper.yml

lxc start $KAFKA_HOSTNAME

../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

lxc exec $KAFKA_HOSTNAME -- docker swarm join --token $DOCKER_SWARM_WORKER_JOIN_TOKEN bcm-gateway-01:2377

# if it's the first instance, let's download the kafka image from
# docker hub; then we tag and push to our local private registry
# so subsequent kafka nodes can just download from there.


REGISTRY="bcm-gateway-01:5010"
ZOOKEEPER_IMAGE="$REGISTRY/bcm-zookeeper:latest"
KAFKA_IMAGE="$REGISTRY/bcm-kafka:latest"

if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
    lxc exec $KAFKA_HOSTNAME -- docker pull zookeeper
    lxc exec $KAFKA_HOSTNAME -- docker pull confluentinc/cp-kafka

    lxc exec $KAFKA_HOSTNAME -- docker tag zookeeper $ZOOKEEPER_IMAGE
    lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka $KAFKA_IMAGE

    lxc exec $KAFKA_HOSTNAME -- docker push $ZOOKEEPER_IMAGE
    lxc exec $KAFKA_HOSTNAME -- docker push $KAFKA_IMAGE


    lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$ZOOKEEPER_IMAGE" ZOOKEEPER_LXC_HOSTNAME="bcm-zookeeper-01" OVERLAY_NETWORK_NAME="zookeeper_01" TARGET_HOST="$KAFKA_HOSTNAME" ZOOKEPER_ID="1" ZOOKEEPER_SERVERS="server.1=0.0.0.0:2888:3888" docker stack deploy -c /root/stacks/zookeeper.yml zookeeper-01

    lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka $PRIVATE_REGISTRY/bcm-kafka:latest
    lxc exec $KAFKA_HOSTNAME -- docker push $PRIVATE_REGISTRY/bcm-kafka:latest
fi




# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    if [[ $endpoint != $MASTER_NODE ]]; then
        HOST_ENDING=$(echo $endpoint | tail -c 2)
        KAFKA_HOSTNAME="bcm-kafka-$(printf %02d $HOST_ENDING)"

        if [[ $HOST_ENDING -ge 2 ]]; then
            lxc file push ./kafka.daemon.json $KAFKA_HOSTNAME/etc/docker/daemon.json

            lxc start $KAFKA_HOSTNAME

            ../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

            # make sure gateway and kafka hosts can reach the swarm master.
            # this steps helps resolve networking before we issue any meaningful
            # commands.
            lxc exec $KAFKA_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:2377
            lxc exec $KAFKA_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:5000
            lxc exec $KAFKA_HOSTNAME -- wait-for-it -t 0 bcm-gateway-02:5001

            # All other LXD bcm-kafka nodes are workers.
            lxc exec $KAFKA_HOSTNAME -- docker swarm join --token $DOCKER_SWARM_WORKER_JOIN_TOKEN bcm-gateway-01:2377


            # We deploy up to 3 zookeeper instances.
            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$ZOOKEEPER_IMAGE" ZOOKEEPER_LXC_HOSTNAME="bcm-zookeeper-$(printf %02d $HOST_ENDING)" OVERLAY_NETWORK_NAME="zookeeper_$(printf %02d $HOST_ENDING)" TARGET_HOST="$KAFKA_HOSTNAME" ZOOKEPER_ID="$HOST_ENDING" ZOOKEEPER_SERVERS="server.$HOST_ENDING=0.0.0.0:2888:3888" docker stack deploy -c /root/stacks/zookeeper.yml "zookeeper-$(printf %02d $HOST_ENDING)"
            fi
        fi
    fi
done
