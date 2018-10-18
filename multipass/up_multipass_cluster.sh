#!/bin/bash

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.

set -e

# let's the arguments passed in on the terminal
# member count is really the number of nodes BEYOND the first cluster member.
MEMBER_COUNT=0
while getopts c:m: option
do
    case "${option}"
    in
    c) export BCM_CLUSTER_NAME=${OPTARG};;
    m) export MEMBER_COUNT=${OPTARG};;
    esac
done

# the master is always going to be '$BCM_CLUSTER_NAME-00'
export BCM_MULTIPASS_VM_NAME="$BCM_CLUSTER_NAME-00"

# we use this later since BCM_MULTIPASS_VM_NAME changes for each VM
export BCM_LXD_CLUSTER_MASTER=$BCM_MULTIPASS_VM_NAME

# to shorten reference to the cluster ~/.bcm directory
export CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME

# if ~/.bcm/clusters doesn't exist, create it.
if [ ! -d ~/.bcm/clusters ]; then
  echo "Creating BCM clusters directory at ~/.bcm/clusters"
  mkdir -p ~/.bcm/clusters
fi

# if ~/.bcm/clusters doesn't exist, create it.
export ENDPOINTS_DIR="$CLUSTER_DIR/endpoints"
if [ ! -d $ENDPOINTS_DIR ]; then
  echo "Creating directory $ENDPOINTS_DIR"
  mkdir -p $ENDPOINTS_DIR
fi

export NEWVM_DIR="$ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME"
if [ ! -d $NEWVM_DIR ]; then
  echo "Creating BCM clusters directory at $NEWVM_DIR"
  mkdir -p $NEWVM_DIR
fi

# stub and source the master .env file
bash -c "./stub_env.sh master"
source $NEWVM_DIR/.env

# create the master multipass VM if it doesn't exist yet.
if [[ -z $(multipass list | grep $BCM_MULTIPASS_VM_NAME) ]]; then
    bash -c "./multipass_vm_up.sh true null $BCM_MULTIPASS_VM_NAME"
else
    echo "Multipass VM $BCM_MULTIPASS_VM_NAME already exists. Continuing with existing VM."
fi

# now provision the other nodes.
if [[ $MEMBER_COUNT -ge 1 ]]; then
    # spin up some member nodes
    echo "Member Count: $MEMBER_COUNT"
    for i in $(seq -f %02g 1 $MEMBER_COUNT)
    do
        echo "$BCM_CLUSTER_NAME-$i"
        export BCM_MULTIPASS_VM_NAME="$BCM_CLUSTER_NAME-$i"
        export NEWVM_DIR="$ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME"
        bash -c "./stub_env.sh member $BCM_LXD_CLUSTER_MASTER"
        source $NEWVM_DIR/.env
        bash -c "./multipass_vm_up.sh false $BCM_LXD_CLUSTER_MASTER $BCM_MULTIPASS_VM_NAME"
    done
fi

# run the 'bcm' command to load bcm the environment variables
source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh
