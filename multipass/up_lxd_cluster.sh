#!/bin/bash

set -eu

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.
MEMBER_COUNT=


# todo make sure $1 is an integer >=1
if [[ -z $1 ]]; then
    MEMBER_COUNT=1
else 
    MEMBER_COUNT=$2
fi

# if ~/.bcm/clusters doesn't exist, create it.
if [ ! -d ~/.bcm/clusters ]; then
  echo "Creating BCM clusters directory at ~/.bcm/clusters"
  mkdir -p ~/.bcm/clusters
fi

# let's get the cluster name passed in from the commandline
export BCM_CLUSTER_NAME=$1
export BCM_MULTIPASS_VM_NAME="$BCM_CLUSTER_NAME-00"
export BCM_LXD_CLUSTER_MASTER=$BCM_MULTIPASS_VM_NAME

if [[ ! -d ~/.bcm/clusters/$BCM_CLUSTER_NAME ]]; then
    mkdir -p ~/.bcm/clusters/$BCM_CLUSTER_NAME 
fi

if [[ ! -d ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME ]]; then
    mkdir -p ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME
fi

bash -c "./stub_env.sh master"
source ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/.env

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
        export BCM_MULTIPASS_VM_NAME="$BCM_CLUSTER_NAME-$i"
        bash -c "./stub_env.sh member $BCM_LXD_CLUSTER_MASTER"
        source ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/.env
        bash -c "./multipass_vm_up.sh false $BCM_LXD_CLUSTER_MASTER $BCM_MULTIPASS_VM_NAME"
    done
fi

# run the 'bcm' command to load bcm the environment variables
source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh
