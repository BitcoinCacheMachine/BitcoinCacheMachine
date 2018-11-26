#!/bin/bash

set -Eeuo pipefail
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

    # remove swarm services related to kafka
    if ! lxc list | grep -q "bcm-gateway-01"; then
        for NODE_ID in $(lxc exec bcm-gateway-01 -- docker node list | grep "$KAFKA_HOST" | awk '{print $1;}'); do
            lxc exec bcm-gateway-01 -- docker node rm "$NODE_ID" --force
        done
    fi

    if [[ ! -z $(lxc list | grep "$KAFKA_HOST") ]]; then
        lxc delete "$KAFKA_HOST" --force
    fi


    if [[ ! -z $(lxc storage volume list "bcm_btrfs" | grep "$KAFKA_HOST-dockerdisk") ]]; then
        lxc storage volume delete "bcm_btrfs" "$KAFKA_HOST-dockerdisk" --target "$endpoint"
    fi
done

if lxc profile list | grep -q "bcm_kafka_profile"; then
    lxc profile delete bcm_kafka_profile
fi