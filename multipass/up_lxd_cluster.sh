#!/bin/bash

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.
MEMBER_COUNT=
# todo make sure $1 is an integer >2
if [[ -z $1 ]]; then
    MEMBER_COUNT=0
else 
    MEMBER_COUNT=$1
fi

export BCM_MULTIPASS_VM_NAME="bcm-01"
export BCM_LXD_CLUSTER_MASTER=$BCM_MULTIPASS_VM_NAME
bash -c "./stub_env.sh master"
source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env

bash -c "./stub_cloud-init.sh master $BCM_MULTIPASS_VM_NAME"
bash -c "./multipass_vm_up.sh true null $BCM_MULTIPASS_VM_NAME"

if [[ $MEMBER_COUNT -ge 1 ]]; then
    # spin up some member nodes
    for i in {1..$MEMBER_COUNT}
    do
        export BCM_MULTIPASS_VM_NAME="bcm-02"
        bash -c "./stub_env.sh member $BCM_LXD_CLUSTER_MASTER"
        source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
        bash -c "./stub_cloud-init.sh member $BCM_LXD_CLUSTER_MASTER"
        bash -c "./multipass_vm_up.sh false $BCM_LXD_CLUSTER_MASTER $BCM_MULTIPASS_VM_NAME"
    done
fi