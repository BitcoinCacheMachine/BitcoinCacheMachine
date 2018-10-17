#!/bin/bash

set -eu

export BCM_CLUSTER_NAME=$1

VM_DELETE_LIST=$(multipass list --format csv | cut -d ',' -f1 | grep -v '^Name' | grep "$BCM_CLUSTER_NAME")

for vm in $VM_DELETE_LIST
do
    echo "Working on VM: $vm"
    export BCM_MULTIPASS_VM_NAME=$vm
    bash -c "./destroy_multipass.sh $BCM_MULTIPASS_VM_NAME"
done

if [[ -d ~/.bcm/clusters/$BCM_CLUSTER_NAME ]]; then
  rm -rf ~/.bcm/clusters/$BCM_CLUSTER_NAME
fi


cd ~/.bcm
git add *
git commit -am "Removed ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/"
cd -