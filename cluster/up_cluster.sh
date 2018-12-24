#!/bin/bash

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_CLUSTER_NODE_COUNT=
BCM_CLUSTER_NAME=
BCM_PROVIDER_NAME="baremetal"
BCM_MGMT_TYPE=
BCM_CLUSTER_MASTER_NAME=

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --node-count=*)
            BCM_CLUSTER_NODE_COUNT="${i#*=}"
            shift # past argument=value
        ;;
        --provider=*)
            BCM_PROVIDER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --mgmt-type=*)
            BCM_MGMT_TYPE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ $BCM_DEBUG == 1 ]]; then
    echo "Running up_cluster.sh with the following parameters."
    echo "BCM_CLUSTER_NODE_COUNT: '$BCM_CLUSTER_NODE_COUNT'"
    echo "BCM_CLUSTER_NAME: '$BCM_CLUSTER_NAME'"
    echo "BCM_PROVIDER_NAME: '$BCM_PROVIDER_NAME'"
    echo "BCM_MGMT_TYPE: '$BCM_MGMT_TYPE'"
fi

# see if the directory exists already; if so we exit
# shellcheck disable=2153
export BCM_CLUSTER_DIR=$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME
if [[ -d $BCM_CLUSTER_DIR ]]; then
    echo "ERROR: The BCM_CLUSTER_DIR directory already exists. Exiting."
    exit
else
    mkdir -p "$BCM_CLUSTER_DIR"
fi

if [[ $BCM_PROVIDER_NAME == "baremetal" ]]; then
    BCM_CLUSTER_NODE_COUNT=1
fi

# elif [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
# bash -c "$BCM_GIT_DIR/cluster/providers/multipass/snap_multipass_install.sh"

BCM_CLUSTER_ENDPOINT_NAME="$BCM_CLUSTER_NAME-01"
BCM_CLUSTER_MASTER_NAME=$BCM_CLUSTER_ENDPOINT_NAME

# if $BCM_RUNTIME_DIR/clusters doesn't exist, create it.
export ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"
if [ ! -d "$ENDPOINTS_DIR" ]; then
    echo "Creating directory $ENDPOINTS_DIR"
    mkdir -p "$ENDPOINTS_DIR"
fi

export BCM_ENDPOINT_DIR="$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME"
if [ ! -d "$BCM_ENDPOINT_DIR" ]; then
    echo "Creating BCM cluster endpoint directory at $BCM_ENDPOINT_DIR"
    mkdir -p "$BCM_ENDPOINT_DIR" >>/dev/null
fi

./stub_env.sh --endpoint-name="$BCM_CLUSTER_MASTER_NAME" --master --endpoint-dir="$BCM_ENDPOINT_DIR" --provider="$BCM_PROVIDER_NAME" --network-interface="wlp1s0"

# shellcheck source=/dev/null
source "$BCM_ENDPOINT_DIR/.env"

# substitute the variables in lxd_master_preseed.yml
# shellcheck disable=SC2016
BCM_LXD_CORE_HTTPS_ADDRESS='$BCM_LXD_CORE_HTTPS_ADDRESS'
export BCM_LXD_CORE_HTTPS_ADDRESS

if [[ $BCM_PROVIDER_NAME == "baremetal" ]]; then
    BCM_LXD_CORE_HTTPS_ADDRESS="127.0.10.1:8443"
fi

envsubst <./lxd_preseed/lxd_master_preseed.yml >"$BCM_ENDPOINT_DIR/lxd_preseed.yml"
BCM_CLUSTER_MASTER_ENDPOINT_DIR="$BCM_ENDPOINT_DIR"

# create the endpoint using the underlying provider
./up_cluster_endpoint.sh --master --cluster-name="$BCM_CLUSTER_NAME" --endpoint-name="$BCM_CLUSTER_ENDPOINT_NAME" --provider="$BCM_PROVIDER_NAME" --endpoint-dir="$BCM_CLUSTER_MASTER_ENDPOINT_DIR"

# get the IP address of the new endpoint
BCM_CLUSTER_MASTER_ENDPOINT_IP=$(bash -c "./get_endpoint_ip.sh --provider=$BCM_PROVIDER_NAME --endpoint-name=$BCM_CLUSTER_ENDPOINT_NAME")
export BCM_CLUSTER_MASTER_ENDPOINT_IP

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
CERT_FILE=$BCM_ENDPOINT_DIR/lxd.cert
if [[ -d $BCM_ENDPOINT_DIR ]]; then
    # makre sure we're on the correct LXC remote
    if [[ $(lxc remote get-default) == "$BCM_CLUSTER_NAME" ]]; then
        # get the cluster master certificate using LXC.
        touch "$CERT_FILE"
        lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \\t]*//" >>"$CERT_FILE"
    fi
fi

#########################################
# create the other members of the cluster.
# now provision the other nodes.
if [[ $BCM_CLUSTER_NODE_COUNT -ge 2 ]]; then
    
    # let's the the BCM_LXD_SECRET from the master.
    # shellcheck source=/dev/null
    source "$BCM_CLUSTER_MASTER_ENDPOINT_DIR/.env"
    export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET
    
    if [[ -f $BCM_ENDPOINT_DIR/lxd.cert ]]; then
        BCM_LXD_CLUSTER_CERTIFICATE=$(sed ':a;N;$!ba;s/\n/\n\n/g' "$BCM_ENDPOINT_DIR/lxd.cert")
        export BCM_LXD_CLUSTER_CERTIFICATE
    else
        echo "$BCM_ENDPOINT_DIR/lxd.cert does not exist. Cannot create additional cluster members."
    fi
    
    # spin up some member nodes
    echo "Member Count: $BCM_CLUSTER_NODE_COUNT"
    for i in $(seq -f %02g 2 $BCM_CLUSTER_NODE_COUNT); do
        echo "$BCM_CLUSTER_NAME-$i"
        export BCM_CLUSTER_ENDPOINT_NAME="$BCM_CLUSTER_NAME-$i"
        export BCM_CLUSTER_ENDPOINT_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME
        bash -c "./stub_env.sh --endpoint-name=$BCM_CLUSTER_ENDPOINT_NAME --endpoint-type=member --endpoint-dir=$BCM_CLUSTER_ENDPOINT_DIR --provider=$BCM_PROVIDER_NAME"
        
        ENV_FILE=$BCM_CLUSTER_ENDPOINT_DIR/.env
        if [[ -f $ENV_FILE ]]; then
            # shellcheck source=/dev/null
            source "$ENV_FILE"
            
            PRESEED_FILE=./lxd_preseed/lxd_member_preseed.yml
            if [[ -f $PRESEED_FILE ]]; then
                envsubst <./lxd_preseed/lxd_member_preseed.yml >"$BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml"
                # create the endpoint using the underlying provider
                ./up_cluster_endpoint.sh --cluster-name=$BCM_CLUSTER_NAME --endpoint-name="$BCM_CLUSTER_ENDPOINT_NAME" --provider="$BCM_PROVIDER_NAME" --endpoint-dir="$BCM_CLUSTER_ENDPOINT_DIR"
            fi
        fi
    done
fi

# # shellcheck source=/dev/null
# source "$BCM_CERTS_DIR/.env"

# # shellcheck disable=SC2153
# bcm git commit \
#     --cert-dir="$BCM_CERTS_DIR" \
#     --git-repo-dir="$BCM_CLUSTERS_DIR" \
#     --git-commit-message="Created cluster '$BCM_CLUSTER_NAME' and associated endpoints." \
#     --git-username="$BCM_CERT_USERNAME" \
#     --email-address="$BCM_CERT_USERNAME@$BCM_CERT_FQDN" \
#     --gpg-signing-key-id="$BCM_DEFAULT_KEY_ID"
