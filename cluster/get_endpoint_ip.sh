#!/bin/bash

set -eu

BCM_CLUSTER_PROVIDER=$1
BCM_CLUSTER_ENDPOINT_NAME=$2
BCM_ENDPOINT_VM_IP=

if [[ $BCM_CLUSTER_PROVIDER = "multipass" ]]; then
    BCM_ENDPOINT_VM_IP=$(multipass list | grep "$BCM_CLUSTER_ENDPOINT_NAME" | awk '{ print $3 }')
fi

echo "$BCM_ENDPOINT_VM_IP"