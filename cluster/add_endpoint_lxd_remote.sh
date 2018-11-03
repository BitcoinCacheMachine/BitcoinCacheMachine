#!/bin/bash

set -eu

BCM_CLUSTER_ENDPOINT_NAME=
BCM_ENDPOINT_VM_IP=
BCM_LXD_SECRET=

for i in "$@"
do
case $i in
    --endpoint=*)
    BCM_CLUSTER_ENDPOINT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --endpoint-ip=*)
    BCM_ENDPOINT_VM_IP="${i#*=}"
    shift # past argument=value
    ;;
    --endpoint-lxd-secret=*)
    BCM_LXD_SECRET="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


echo "Waiting for the remote lxd daemon to become available."
wait-for-it -t 0 $BCM_ENDPOINT_VM_IP:8443

echo "Adding a lxd remote for $BCM_CLUSTER_ENDPOINT_NAME at $BCM_ENDPOINT_VM_IP:8443."
lxc remote add $BCM_CLUSTER_ENDPOINT_NAME "$BCM_ENDPOINT_VM_IP:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote set-default $BCM_CLUSTER_ENDPOINT_NAME

echo "Current lxd remote default is $BCM_CLUSTER_ENDPOINT_NAME."