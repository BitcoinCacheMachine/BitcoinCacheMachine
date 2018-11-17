#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh

MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    #echo $endpoint
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME="bcm-kafka-$(printf %02d $HOST_ENDING)"

    if [[ ! -z $(lxc list | grep "$LXD_CONTAINER_NAME") ]]; then
        lxc delete $LXD_CONTAINER_NAME --force
    fi

    if [[ ! -z $(lxc storage volume list bcm_btrfs | grep "$LXD_CONTAINER_NAME-dockerdisk") ]]; then
        lxc storage volume delete bcm_btrfs "$LXD_CONTAINER_NAME-dockerdisk" --target $endpoint
    fi
done

# delete the profile bcm_kafka_profile

if [[ ! -z $(lxc profile list | grep "bcm_kafka_profile") ]]; then
    lxc profile delete bcm_kafka_profile
fi
