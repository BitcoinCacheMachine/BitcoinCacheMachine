#!/bin/bash

set -eu

BCM_CLUSTER_ENDPOINT_NAME=$1
BCM_ENDPOINT_VM_IP=$2
BCM_LXD_SECRET=$3

echo "Waiting for the remote lxd daemon to become available."
wait-for-it -t 0 $BCM_ENDPOINT_VM_IP:8443

echo "Adding a lxd remote for $BCM_CLUSTER_ENDPOINT_NAME at $BCM_ENDPOINT_VM_IP:8443."
lxc remote add $BCM_CLUSTER_ENDPOINT_NAME "$BCM_ENDPOINT_VM_IP:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote set-default $BCM_CLUSTER_ENDPOINT_NAME

echo "Current lxd remote default is $BCM_CLUSTER_ENDPOINT_NAME."