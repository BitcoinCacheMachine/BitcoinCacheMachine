#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")" 

# quit if the template isn't there.
if ! lxc image show "bcm-template" | grep -q "release:"; then
    echo "Required LXC image 'bcm-template' does not exist. Exiting"
    exit
fi

# create the 'bcm_ui_dmz' lxc profile
if ! lxc profile list | grep -q "bcm_ui_dmz"; then
    lxc profile create bcm_ui_dmz
fi

# apply the default kafka.yml
lxc profile edit bcm_ui_dmz < ./lxd_profiles/bcm_ui_dmz.yml

# get all the bcm-kafka-xx containers deployed to the cluster.
bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/spread_lxc_hosts.sh --hostname=uidmz"

# shellcheck disable=SC1090
source "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/get_docker_swarm_tokens.sh"

PRIVATE_REGISTRY="bcm-gateway-01:5010"
LXC_HOSTNAME="bcm-uidmz-01"

if [[ -z $PRIVATE_REGISTRY ]]; then
    echo "PRIVATE_REGISTRY MUST be set."
    exit
fi

if ! lxc list | grep -q "$LXC_HOSTNAME"; then
    echo "'$LXC_HOSTNAME' does not exist. Can't provision ui_dmz services."
    exit
fi

lxc file push ./uidmz.daemon.json "$LXC_HOSTNAME/etc/docker/daemon.json"
lxc file push -r -p ./docker_stacks/* bcm-gateway-01/root/stacks/ui_dmz

# lxc start $KAFKA_HOSTNAME

# ../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

# lxc exec $KAFKA_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:2377

# lxc exec $KAFKA_HOSTNAME -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377

# # if it's the first instance, let's download the kafka image from
# # docker hub; then we tag and push to our local private registry
# # so subsequent kafka nodes can just download from there.


# REGISTRY="bcm-gateway-01:5010"
# ZOOKEEPER_IMAGE="$REGISTRY/bcm-zookeeper:latest"
# KAFKA_IMAGE="$REGISTRY/bcm-kafka:latest"


# if [[ $KAFKA_HOSTNAME = "bcm-kafka-01" ]]; then
#     lxc exec $KAFKA_HOSTNAME -- docker pull zookeeper
#     lxc exec $KAFKA_HOSTNAME -- docker pull confluentinc/cp-kafka

#     lxc exec $KAFKA_HOSTNAME -- docker tag zookeeper "$ZOOKEEPER_IMAGE"
#     lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka "$KAFKA_IMAGE"

#     lxc exec $KAFKA_HOSTNAME -- docker push "$ZOOKEEPER_IMAGE"
#     lxc exec $KAFKA_HOSTNAME -- docker push "$KAFKA_IMAGE"

#     lxc exec $KAFKA_HOSTNAME -- docker tag confluentinc/cp-kafka "$PRIVATE_REGISTRY/bcm-kafka:latest"
#     lxc exec $KAFKA_HOSTNAME -- docker push "$PRIVATE_REGISTRY/bcm-kafka:latest"
# fi




# # let's cycle through the other cluster members (other than the master)
# # and get their bcm-kafka-XX LXC host deployed
# for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
#     if [[ "$endpoint" != "$MASTER_NODE" ]]; then
#         HOST_ENDING=$(echo "$endpoint" | tail -c 2)
#         KAFKA_HOSTNAME="bcm-kafka-$(printf %02d "$HOST_ENDING")"

#         if [[ "$HOST_ENDING" -ge 2 ]]; then
#             lxc file push ./kafka.daemon.json "$KAFKA_HOSTNAME/etc/docker/daemon.json"

#             lxc start "$KAFKA_HOSTNAME"

#             ../../shared/wait_for_dockerd.sh --container-name="$KAFKA_HOSTNAME"

#             # make sure gateway and kafka hosts can reach the swarm master.
#             # this steps helps resolve networking before we issue any meaningful
#             # commands.
#             lxc exec "$KAFKA_HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:2377
#             lxc exec "$KAFKA_HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:5000
#             lxc exec "$KAFKA_HOSTNAME" -- wait-for-it -t 0 bcm-gateway-02:5001

#             # All other LXD bcm-kafka nodes are workers.
#             lxc exec "$KAFKA_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
#         fi
#     fi
# done

