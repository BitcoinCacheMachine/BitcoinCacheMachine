#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh
source ../host_template/defaults.sh

# At a high level, this script works to get kafka LXC nodes desployed
# to an existing BCM cluster. There will always be kafka node on each
# hardware failure domain.

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Cannot deploy kafka nodes."
    exit
fi

# if bcmNet doesn't exist, we can't continue.
if [[ -z $(lxc network list | grep bcmNet | grep CREATED) ]]; then 
    echo "Required LXC network bcmNet does not exist. Cannot deploy kafka nodes."
    exit
fi

# create the 'bcm_kafka_profile' lxc profile
if [[ -z $(lxc profile list | grep "bcm_kafka_profile") ]]; then
    lxc profile create bcm_kafka_profile
fi

# apply the default profile.
if [[ ! -z $(lxc profile list | grep "bcm_kafka_profile") ]]; then
    cat ./bcm_kafka_profile.yml | lxc profile edit bcm_kafka_profile
fi

# let's make sure we have the dockertemplate to init from.
if [[ -z $(lxc list | grep "$BCM_HOSTTEMPLATE_NAME") ]]; then
    echo "Error. LXC host '$BCM_HOSTTEMPLATE_NAME' doesn't exist."
    exit
fi

# let's deploy a kafka lxc host to each cluster node.
MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME="bcm-kafka-$(printf %02d $HOST_ENDING)"
    DOCKERVOL="$LXD_CONTAINER_NAME-dockerdisk"
    
    echo "Creating volume '$DOCKERVOL' on storage pool bcm_btrfs on cluster member '$endpoint'."
    if [ $endpoint != $MASTER_NODE ]; then
        lxc storage volume create bcm_btrfs $DOCKERVOL block.filesystem=ext4 --target $endpoint
    else
        lxc storage volume create bcm_btrfs $DOCKERVOL block.filesystem=ext4
    fi
    
    lxc init --target $endpoint bcm-template $LXD_CONTAINER_NAME --profile=bcm_default --profile=docker_privileged -p bcm_kafka_profile

    lxc storage volume attach bcm_btrfs $DOCKERVOL $LXD_CONTAINER_NAME dockerdisk path=/var/lib/docker

    #lxc file push ./gateway_ip_addr_template.yml $LXD_CONTAINER_NAME/etc/netplan/10-lxc.yaml
done

# let's start the LXD container on the LXD cluster master.
LXD_CONTAINER_NAME="bcm-kafka-01"
lxc start $LXD_CONTAINER_NAME

../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

PRIVATE_REGISTRY="bcm-kafka-01:5010"
lxc exec $LXD_CONTAINER_NAME -- docker pull confluentinc/cp-kafka
lxc exec $LXD_CONTAINER_NAME -- docker tag confluentinc/cp-kafka $PRIVATE_REGISTRY/bcm-kafka:latest
lxc exec $LXD_CONTAINER_NAME -- docker push $PRIVATE_REGISTRY/bcm-kafka:latest

lxc file push daemon1.json $LXD_CONTAINER_NAME/etc/docker/daemon.json

lxc file push ./gw_docker_stack/ $LXD_CONTAINER_NAME/root/stacks/ -p -r

lxc exec $LXD_CONTAINER_NAME -- docker swarm init --advertise-addr eth1 >> /dev/null

lxc restart $LXD_CONTAINER_NAME

# ../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

# lxc exec $LXD_CONTAINER_NAME -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5000 TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/gw_docker_stack/registry_mirror.yml regmirror
# lxc exec $LXD_CONTAINER_NAME -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5010 TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/gw_docker_stack/private_registry.yml privateregistry

# lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 $LXD_CONTAINER_NAME:5000
# lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 $LXD_CONTAINER_NAME:5010

# sleep 3

# # first let's push the local registry image in our dockerd to the registry cache
# # so other nodes can dowload it.
# PRIVATE_REGISTRY="bcm-gateway-01:5010"

# lxc exec $LXD_CONTAINER_NAME -- docker tag registry:latest $PRIVATE_REGISTRY/bcm-registry:latest
# lxc exec $LXD_CONTAINER_NAME -- docker push $PRIVATE_REGISTRY/bcm-registry:latest


# # now let's build some custom images that we're going run on each bcm-gateway
# # namely TOR
# export BCM_DOCKER_BASE_IMAGE="ubuntu:bionic"

# lxc exec $LXD_CONTAINER_NAME -- docker pull $BCM_DOCKER_BASE_IMAGE
# lxc exec $LXD_CONTAINER_NAME -- docker tag $BCM_DOCKER_BASE_IMAGE $PRIVATE_REGISTRY/bcm-bionic-base:latest
# lxc exec $LXD_CONTAINER_NAME -- docker push $PRIVATE_REGISTRY/bcm-bionic-base:latest
# lxc file push ./bcm-base.Dockerfile $LXD_CONTAINER_NAME/root/Dockerfile
# lxc exec $LXD_CONTAINER_NAME -- docker build -t $PRIVATE_REGISTRY/bcm-base:latest .

# lxc exec $LXD_CONTAINER_NAME -- mkdir -p /root/stacks/tor
# lxc file push ./tor/bcm-tor.Dockerfile $LXD_CONTAINER_NAME/root/stacks/tor/Dockerfile

# TOR_IMAGE="$PRIVATE_REGISTRY/bcm-tor:latest"
# lxc exec $LXD_CONTAINER_NAME -- docker build -t $TOR_IMAGE /root/stacks/tor/
# lxc exec $LXD_CONTAINER_NAME -- docker push $TOR_IMAGE
# lxc exec $LXD_CONTAINER_NAME -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c /root/stacks/gw_docker_stack/tor_socks5_dns.yml torsocksdns

# # let's cycle through the other cluster members (other than the master)
# # and get their bcm-gateway host going.


# DOCKER_SWARM_MANAGER_JOIN_TOKEN=$(lxc exec bcm-gateway-01 -- docker swarm join-token manager | grep token | awk '{ print $5 }')
# #DOCKER_SWARM_WORKER_JOIN_TOKEN=$(lxc exec $LXD_CONTAINER_NAME -- docker swarm join-token worker | grep token | awk '{ print $5 }')

# for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
#     if [[ $endpoint != $MASTER_NODE ]]; then
#         HOST_ENDING=$(echo $endpoint | tail -c 2)
#         LXD_CONTAINER_NAME="bcm-gateway-$(printf %02d $HOST_ENDING)"

#         if [[ $HOST_ENDING -ge 2 ]]; then
#             lxc file push member.daemon.json $LXD_CONTAINER_NAME/etc/docker/daemon.json

#             lxc start $LXD_CONTAINER_NAME

#             ../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

#             lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:2377
#             lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:5000
#             lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:5010
            
#             # we will stop at 3 manager hosts; should be adequate.
#             if [[ $HOST_ENDING -le 3 ]]; then
#                 lxc exec $LXD_CONTAINER_NAME -- docker swarm join --token $DOCKER_SWARM_MANAGER_JOIN_TOKEN bcm-gateway-01:2377
#             fi

#             # only do this if we're on our second node. We're going to deploy
#             # another registry mirror and private registry in case node1 goes offline.
#             # We will only have 2 locations for docker image distribution.
#             if [[ $HOST_ENDING = 2 ]]; then
#                 lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5001 TARGET_HOST=$LXD_CONTAINER_NAME REGISTRY_PROXY_REMOTEURL="http://bcm-gateway-01:5000" docker stack deploy -c /root/stacks/gw_docker_stack/registry_mirror.yml regmirror2
#                 lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5011 TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/gw_docker_stack/private_registry.yml privateregistry2
#             fi
#         fi
#     fi
# done


















# #!/bin/bash

# set -eu
# cd "$(dirname "$0")"

# lxc network create lxdbrManager1

# # Managernet is used by any docker host that joins the swarm hosted by the managers.
# echo "Creating lxd network 'managernet' for swarm members."
# lxc network create managernet ipv4.address=10.0.0.1/24 ipv4.nat=false ipv6.nat=false



# # create the docker profile if it doesn't exist. This may happen when we have an external cachestack 
# # and we didn't create the profile during the host_template creation.
# if [[ -z $(lxc profile list | grep docker) ]]; then
#   lxc profile create docker
#   cat ../../bcs/host_template/docker_lxd_profile.yml | lxc profile edit docker
# fi


# # create the docker_privileged profile if it doesn't exist, which might happen when we're using an external cachestack
# if [[ -z $(lxc profile list | grep "docker_privileged") ]]; then
#   lxc profile create docker_privileged
#   cat ../../bcs/host_template/lxd_profile_docker_template.yml | lxc profile edit docker_privileged
# fi

# ## Create the manager1 host from the lxd image template.
# lxc init bcm-template manager-template -p docker -p docker_privileged -s "bcm_d1ata"

# # push necessary files to the template including daemon.json
# lxc file push ./daemon.json manager-template/etc/docker/daemon.json

# # create a snapshot from which all production managers will be based.
# lxc snapshot manager-template "managerTemplate"

# ## Start and configure the managers.
# # create manager1

# lxc profile create manager1
# cat ./lxd_profiles/manager1.yml | lxc profile edit manager1

# lxc copy manager-template/managerTemplate manager1
# lxc profile apply manager1 default,manager1

# if [[ -z $(lxc storage list | grep "manager1-dockervol") ]]; then
#   # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
#   lxc storage create manager1-dockervol dir
# fi

# # attach the dockerdisk to manager1 assuming 'manager1-dockervol' exists.
# ## TODO AND it's not already attached.
# if [[ $(lxc storage list | grep "manager1-dockervol") ]]; then
#   lxc config device add manager1 dockerdisk disk source="$(lxc storage show manager1-dockervol | grep source | awk 'NF>1{print $NF}')" path=/var/lib/docker 
# fi


# lxc start manager1

# # wait for the machine to start
# # TODO find a better way to wait
# sleep 10

# lxc exec manager1 -- ifmetric eth0 0

# lxc exec manager1 -- docker swarm init --advertise-addr=10.0.0.11 >/dev/null

# echo "Waiting for manager1 docker swarm service."

# sleep 5

# echo "Creating /apps/kafka inside manager1."
# lxc exec manager1 -- mkdir -p /apps/kafka





# echo "Deploying zookeeper and kafka to the swarm."
# lxc file push ./kafka/zookeeper1.yml manager1/apps/kafka/zookeeper1.yml
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/zookeeper1.yml kafka

# echo "Deploying a Kafka broker to the swarm."
# lxc file push ./kafka/kafka1.yml manager1/apps/kafka/kafka1.yml
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka1.yml kafka

# echo "Deploying Kafka schema-registry to the swarm."
# lxc file push ./kafka/schema-registry.yml manager1/apps/kafka/schema-registry.yml
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/schema-registry.yml kafka

# echo "Deploying Kafka schema-registry-ui to the swarm."
# lxc file push ./kafka/schema-registry-ui.yml manager1/apps/kafka/schema-registry-ui.yml
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/schema-registry-ui.yml kafka

# echo "Deploying Kafka rest to the swarm."
# lxc file push ./kafka/kafka-rest.yml manager1/apps/kafka/kafka-rest.yml
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka-rest.yml kafka

# echo "Deploying Kafka topics-ui to the swarm."
# lxc file push ./kafka/kafka-topics-ui.yml manager1/apps/kafka/kafka-topics-ui.yml
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka-topics-ui.yml kafka

# echo "Deploying logstash to the swarm configured for gelf on TCP 12201."
# lxc file push ./kafka/gelf-listener.yml manager1/apps/kafka/gelf-listener.yml
# lxc file push ./kafka/logstash.conf manager1/apps/kafka/logstash.conf
# lxc exec manager1 -- docker stack deploy -c /apps/kafka/gelf-listener.yml gelf
