#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# remove stateless docker stacks.
bash -c ./connect/destroy_kafka_connect.sh
bash -c ./rest/destroy_kafka_rest.sh
bash -c ./schemareg/destroy_schema-registry.sh

# destry the brokers and zookeeper stacks which are deployed as distinct docker services
bash -c ./broker/destroy_lxc_broker.sh
bash -c ./zookeeper/destroy_zookeeper.sh

# iterate over endpoints and delete actual LXC hosts.
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    KAFKA_HOST="bcm-kafka-$(printf %02d "$HOST_ENDING")"

    bash -c "$BCM_LXD_OPS/remove_docker_node.sh --node-name=$KAFKA_HOST"

    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$KAFKA_HOST"

    bash -c "$BCM_LXD_OPS/delete_cluster_dockerdisk.sh --container-name=$KAFKA_HOST --endpoint=$endpoint"
done

if lxc profile list | grep -q "bcm_kafka_profile"; then
    lxc profile delete bcm_kafka_profile
fi