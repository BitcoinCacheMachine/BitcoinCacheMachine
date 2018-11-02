#!/bin/bash

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.

set -e

cd "$(dirname "$0")"

BCM_CLUSTER_NODE_COUNT=$1
BCM_CLUSTER_NAME=$2
BCM_PROVIDER_NAME=$3
BCM_MGMT_TYPE=$4

if [[ !($BCM_MGMT_TYPE = "local" || $BCM_MGMT_TYPE = "net" || $BCM_MGMT_TYPE = "tor") ]]; then
    echo "Error. BCM_MGMT_TYPE should be either 'local', 'net', or 'tor'."
    exit
fi

echo "BCM_MGMT_TYPE: '$BCM_MGMT_TYPE'"


# see if the directory exists already; if so we exit
export BCM_BCM_CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
if [[ -d $BCM_BCM_CLUSTER_DIR ]]; then
    echo "ERROR: The BCM_BCM_CLUSTER_DIR directory already exists. Exiting."
    exit
fi

function createMaster {
    export BCM_CLUSTER_ENDPOINT_NAME="$BCM_CLUSTER_NAME-00"
    export BCM_LXD_CLUSTER_MASTER=$BCM_CLUSTER_ENDPOINT_NAME
    export BCM_CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME

    # if ~/.bcm/clusters doesn't exist, create it.
    export ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"
    if [ ! -d $ENDPOINTS_DIR ]; then
        echo "Creating directory $ENDPOINTS_DIR"
        mkdir -p $ENDPOINTS_DIR
    fi

    export BCM_ENDPOINT_DIR="$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME"
    if [ ! -d $BCM_ENDPOINT_DIR ]; then
        echo "Creating BCM clusters directory at $BCM_ENDPOINT_DIR"
        mkdir -p $BCM_ENDPOINT_DIR
    fi

    # stub and source the master .env file
    bash -c "./stub_env.sh master $BCM_PROVIDER_NAME"
    source $BCM_ENDPOINT_DIR/.env

    echo "BCM_CLUSTER_ENDPOINT_NAME: $BCM_CLUSTER_ENDPOINT_NAME"
    echo "BCM_PROVIDER_NAME: $BCM_PROVIDER_NAME"
    bash -c "./up_cluster_endpoint.sh true null $BCM_CLUSTER_ENDPOINT_NAME $BCM_PROVIDER_NAME"
}

function createMembers {

    # now provision the other nodes.
    if [[ ! -z $BCM_CLUSTER_NODE_COUNT ]]; then
        if [[ $BCM_CLUSTER_NODE_COUNT -ge 2 ]]; then
            # spin up some member nodes
            echo "Member Count: $BCM_CLUSTER_NODE_COUNT"
            for i in $(seq -f %02g 1 $BCM_CLUSTER_NODE_COUNT)
            do
                echo "$BCM_CLUSTER_NAME-$i"
                export BCM_CLUSTER_ENDPOINT_NAME="$BCM_CLUSTER_NAME-$i"
                export NEWVM_DIR="$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME"
                bash -c "./stub_env.sh member $BCM_PROVIDER_NAME"
                source $NEWVM_DIR/.env
                bash -c "./up_cluster_endpoint.sh false $BCM_LXD_CLUSTER_MASTER"
            done
        fi
    fi
}

if [[ $BCM_PROVIDER_NAME = "lxd" ]]; then
    echo "Performing a local LXD installation (bare-metal). Note this provides no fault tolerance."

    # install docker so we can get started.
    echo "First thing: install LXD which is where all BCM data center components reside."
    bash -c $BCM_LOCAL_GIT_REPO/cluster/providers/lxd/snap_lxd_install.sh
    bash -c $BCM_LOCAL_GIT_REPO/cluster/providers/lxd/provision_lxd.sh

elif [[ $BCM_PROVIDER_NAME = "multipass" ]]; then
    echo "Performing a local LXD installation using multipass. Note this provides no fault tolerance."

    # install multipass so we can get started.
    bash -c $BCM_LOCAL_GIT_REPO/cluster/providers/multipass/snap_multipass_install.sh

    # now we invoke the script that provisions the cluster.
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    export BCM_PROVIDER_NAME=$BCM_PROVIDER_NAME
    
    createMaster
    createMembers
elif [[ $BCM_PROVIDER = "aws" ]]; then
    echo "Creating a remote LXD cluster running on someone else's computers (AWS)."
fi




