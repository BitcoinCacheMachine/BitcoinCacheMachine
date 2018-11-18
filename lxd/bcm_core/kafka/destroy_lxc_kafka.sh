#!/bin/bash

set -eu
cd "$(dirname "$0")"


MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    #echo $endpoint
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    KAFKA_HOST="bcm-kafka-$(printf %02d $HOST_ENDING)"

    if [[ ! -z $(lxc list | grep "$KAFKA_HOST") ]]; then
        lxc delete $KAFKA_HOST --force
    fi

    if [[ ! -z $(lxc storage volume list bcm_btrfs | grep "$KAFKA_HOST-dockerdisk") ]]; then
        lxc storage volume delete bcm_btrfs "$KAFKA_HOST-dockerdisk" --target $endpoint
    fi
done


if [[ ! -z $(lxc profile list | grep "bcm_kafka_profile") ]]; then
    lxc profile delete bcm_kafka_profile
fi
