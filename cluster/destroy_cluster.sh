#!/bin/bash

cd "$(dirname "$0")"

set -eu

if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME incorrectly passed.  Use '-c CLUS1' to pass cluster name."
  exit
fi

echo "Destroying BCM Cluster '$BCM_CLUSTER_NAME'"

export BCM_CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
export ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"

echo "BCM_CLUSTER_DIR=$BCM_CLUSTER_DIR"
echo "ENDPOINTS_DIR=$ENDPOINTS_DIR"

if [[ $(multipass list | grep "$BCM_CLUSTER_NAME") ]]; then
  VM_DELETE_LIST=$(multipass list --format csv | cut -d ',' -f1 | grep -v '^Name' | grep "$BCM_CLUSTER_NAME")

  for vm in $VM_DELETE_LIST
  do
      echo "Working on VM: $vm"
      export BCM_CLUSTER_ENDPOINT_NAME=$vm
      bash -c "./destroy_cluster_endpoint.sh $BCM_CLUSTER_ENDPOINT_NAME"
  done
fi

if [ -d $BCM_CLUSTER_DIR ]; then
  rm -Rf $BCM_CLUSTER_DIR
fi

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh 'Destroyed Cluster $BCM_CLUSTER_NAME and all associted files.'"
