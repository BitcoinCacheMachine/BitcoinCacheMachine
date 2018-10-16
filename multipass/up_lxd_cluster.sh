#!/bin/bash

set -e

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.
MEMBER_COUNT=

# todo make sure $1 is an integer >=1
if [[ -z $1 ]]; then
    MEMBER_COUNT=1
else 
    MEMBER_COUNT=$1
fi

echo "Member Count: $MEMBER_COUNT"

export BCM_MULTIPASS_VM_NAME="bcm-00"
export BCM_LXD_CLUSTER_MASTER=$BCM_MULTIPASS_VM_NAME

if [[ ! -f ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env ]]; then
    bash -c "./stub_env.sh master"
    source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
else
    echo "~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env exists. Continuing with existing values."
fi


# create the master multipass VM if it doesn't exist yet.
if [[ -z $(multipass list | grep $BCM_MULTIPASS_VM_NAME) ]]; then
    bash -c "./multipass_vm_up.sh true null $BCM_MULTIPASS_VM_NAME"
else
    echo "Multipass VM $BCM_MULTIPASS_VM_NAME already exists. Continuing with existing VM."
fi

if [[ $MEMBER_COUNT -ge 1 ]]; then
    # spin up some member nodes
    echo "Member Count: $MEMBER_COUNT"
    for i in $(seq -f %02g 1 $MEMBER_COUNT)
    do
        export BCM_MULTIPASS_VM_NAME="bcm-$i"
        bash -c "./stub_env.sh member $BCM_LXD_CLUSTER_MASTER"
        source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
        bash -c "./multipass_vm_up.sh false $BCM_LXD_CLUSTER_MASTER $BCM_MULTIPASS_VM_NAME"
    done
fi