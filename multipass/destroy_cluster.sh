#!/bin/bash

set -e

while getopts c: option
do
    case "${option}"
    in
    c) export BCM_CLUSTER_NAME=${OPTARG};;
    esac
done

if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME incorrectly passed.  Use '-c CLUS1' to pass cluster name."
  exit
fi

echo "Destroying BCM Cluster '$BCM_CLUSTER_NAME'"

export CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
export ENDPOINTS_DIR="$CLUSTER_DIR/endpoints"

echo "CLUSTER_DIR=$CLUSTER_DIR"
echo "ENDPOINTS_DIR=$ENDPOINTS_DIR"

if [[ $(multipass list | grep "$BCM_CLUSTER_NAME") ]]; then
  VM_DELETE_LIST=$(multipass list --format csv | cut -d ',' -f1 | grep -v '^Name' | grep "$BCM_CLUSTER_NAME")

  for vm in $VM_DELETE_LIST
  do
      echo "Working on VM: $vm"
      export BCM_MULTIPASS_VM_NAME=$vm
      bash -c "./destroy_multipass.sh $BCM_MULTIPASS_VM_NAME"
  done
fi

if [ -d $CLUSTER_DIR ]; then
  rm -Rf $CLUSTER_DIR
fi

bash -c "$BCM_LOCAL_GIT_REPO/resources/commit_bcm.sh 'Destroyed Cluster $BCM_CLUSTER_NAME and all associted files.'"
