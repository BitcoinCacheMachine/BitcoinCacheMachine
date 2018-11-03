#!/bin/bash

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.

set -eu

cd "$(dirname "$0")"

BCM_CLUSTER_NODE_COUNT=$1
BCM_CLUSTER_NAME=$2
BCM_PROVIDER_NAME=$3
BCM_MGMT_TYPE=$4
BCM_LXD_CLUSTER_MASTER=

echo "Running up_cluster.sh with the following parameters."
echo "BCM_CLUSTER_NODE_COUNT: '$BCM_CLUSTER_NODE_COUNT'"
echo "BCM_CLUSTER_NAME: '$BCM_CLUSTER_NAME'"
echo "BCM_PROVIDER_NAME: '$BCM_PROVIDER_NAME'"
echo "BCM_MGMT_TYPE: '$BCM_MGMT_TYPE'"
echo "BCM_LXD_CLUSTER_MASTER: '$BCM_LXD_CLUSTER_MASTER'"


if [[ !($BCM_MGMT_TYPE = "local" || $BCM_MGMT_TYPE = "net" || $BCM_MGMT_TYPE = "tor") ]]; then
    echo "Error. BCM_MGMT_TYPE should be either 'local', 'net', or 'tor'."
    exit
fi


# see if the directory exists already; if so we exit
export BCM_CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
if [[ -d $BCM_CLUSTER_DIR ]]; then
    echo "ERROR: The BCM_CLUSTER_DIR directory already exists. Exiting."
    exit
fi


if [[ $BCM_PROVIDER_NAME = "baremetal" ]]; then
    echo "Performing a local LXD installation (bare-metal). Note this provides no fault tolerance."

    # first let's make sure the lxd snap is installed.
    bash -c $BCM_LOCAL_GIT_REPO/cluster/providers/lxd/snap_lxd_install.sh
    export BCM_PROVIDER_NAME=$BCM_PROVIDER_NAME
elif [[ $BCM_PROVIDER_NAME = "multipass" ]]; then
    echo "Performing a local LXD installation using multipass. Note this provides no fault tolerance."

    # install multipass so we can get started.
    bash -c $BCM_LOCAL_GIT_REPO/cluster/providers/multipass/snap_multipass_install.sh
    
elif [[ $BCM_PROVIDER_NAME = "aws" ]]; then
    echo "Creating a remote LXD cluster running on someone else's computers (AWS)."
else
    echo "Invalid BCM_PROVIDER_NAME"
fi


##### Let's start by creating the master.
export BCM_CLUSTER_ENDPOINT_NAME="$BCM_CLUSTER_NAME-00"
export BCM_LXD_CLUSTER_MASTER=$BCM_CLUSTER_ENDPOINT_NAME

# if ~/.bcm/clusters doesn't exist, create it.
export ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"
if [ ! -d $ENDPOINTS_DIR ]; then
    echo "Creating directory $ENDPOINTS_DIR"
    mkdir -p $ENDPOINTS_DIR
fi

export BCM_ENDPOINT_DIR="$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME"
if [ ! -d $BCM_ENDPOINT_DIR ]; then
    echo "Creating BCM cluster endpoint directory at $BCM_ENDPOINT_DIR"
    mkdir -p $BCM_ENDPOINT_DIR >> /dev/null
fi

# stub and source the master .env file
bash -c "./stub_env.sh $BCM_CLUSTER_ENDPOINT_NAME master $BCM_ENDPOINT_DIR"
source $BCM_ENDPOINT_DIR/.env

echo "BCM_CLUSTER_ENDPOINT_NAME: $BCM_CLUSTER_ENDPOINT_NAME"
echo "BCM_PROVIDER_NAME: $BCM_PROVIDER_NAME"

# substitute the variables in lxd_master_preseed.yml
envsubst < ./lxd_preseed/lxd_master_preseed.yml > $BCM_ENDPOINT_DIR/lxd_preseed.yml
BCM_CLUSTER_MASTER_ENDPOINT_DIR=$BCM_ENDPOINT_DIR
bash -c "./up_cluster_endpoint.sh true $BCM_CLUSTER_ENDPOINT_NAME $BCM_PROVIDER_NAME $BCM_ENDPOINT_DIR"
export BCM_CLUSTER_MASTER_ENDPOINT_IP=`bash -c "./get_endpoint_ip.sh $BCM_PROVIDER_NAME $BCM_CLUSTER_ENDPOINT_NAME"`

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
CERT_FILE=$BCM_ENDPOINT_DIR/lxd.cert
if [[ -d $BCM_ENDPOINT_DIR ]]; then
    # makre sure we're on the correct LXC remote
    if [[ $(lxc remote get-default) = $BCM_CLUSTER_ENDPOINT_NAME ]]; then
        # get the cluster master certificate using LXC.
        touch $CERT_FILE
        lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \t]*//" >> $CERT_FILE
    fi
fi




#########################################
# create the other members of the cluster.
# now provision the other nodes.
if [[ $BCM_CLUSTER_NODE_COUNT -ge 2 ]]; then

    # let's the the BCM_LXD_SECRET from the master.
    source $BCM_CLUSTER_MASTER_ENDPOINT_DIR/.env
    export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET

    if [[ -f $BCM_ENDPOINT_DIR/lxd.cert ]]; then
        export BCM_LXD_CLUSTER_CERTIFICATE=$(sed ':a;N;$!ba;s/\n/\n\n/g' $BCM_ENDPOINT_DIR/lxd.cert)
    else
        echo "$BCM_ENDPOINT_DIR/lxd.cert does not exist. Cannot create additional cluster members."
    fi

    # spin up some member nodes
    echo "Member Count: $BCM_CLUSTER_NODE_COUNT"
    for i in $(seq -f %02g 1 $BCM_CLUSTER_NODE_COUNT)
    do
        echo "$BCM_CLUSTER_NAME-$i"
        export BCM_CLUSTER_ENDPOINT_NAME="$BCM_CLUSTER_NAME-$i"
        export BCM_ENDPOINT_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME
        bash -c "./stub_env.sh $BCM_CLUSTER_ENDPOINT_NAME member $BCM_ENDPOINT_DIR $BCM_PROVIDER_NAME"
        source $BCM_ENDPOINT_DIR/.env
        BCM_ENDPOINT_VM_IP=`bash -c "./get_endpoint_ip.sh $BCM_PROVIDER_NAME $BCM_CLUSTER_ENDPOINT_NAME"`
        envsubst < ./lxd_preseed/lxd_member_preseed.yml > $BCM_ENDPOINT_DIR/lxd_preseed.yml
        bash -c "./up_cluster_endpoint.sh false $BCM_CLUSTER_ENDPOINT_NAME $BCM_PROVIDER_NAME $BCM_ENDPOINT_DIR"
    done
fi
