#!/bin/bash

set -o nounset
cd "$(dirname "$0")"

BCM_HELP_FLAG=0

VALUE=${2:-}
if [ ! -z ${VALUE} ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

BCM_CLUSTER_NAME=
BCM_NODE_COUNT=
BCM_ENDPOINTS_FLAG=0
BCM_SSH_HOSTNAME=
BCM_SSH_USERNAME="$(whoami)"
BCM_LXD_HOSTNAME=

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-hostname=*)
            BCM_SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --username=*)
            BCM_SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --node-count=*)
            BCM_NODE_COUNT="${i#*=}"
            shift # past argument=value
        ;;
        --endpoints)
            BCM_ENDPOINTS_FLAG=1
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ -z $BCM_CLUSTER_NAME ]]; then
    BCM_CLUSTER_NAME=$(lxc remote get-default)
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    export BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"
    export BCM_SSH_USERNAME="$BCM_SSH_USERNAME"
    
    bash -c "$BCM_GIT_DIR/cluster/up_cluster.sh --cluster-name=$BCM_CLUSTER_NAME --node-count=$BCM_NODE_COUNT"
    
    elif [[ $BCM_CLI_VERB == "destroy" ]]; then
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    bash -c "$BCM_GIT_DIR/cluster/destroy_cluster.sh --cluster-name=$BCM_CLUSTER_NAME"
    elif [[ $BCM_CLI_VERB == "list" ]]; then
    
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    
    # shellcheck disable=SC2153
    export BCM_ENDPOINTS_FLAG=$BCM_ENDPOINTS_FLAG
    
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        
        if lxc info | grep -q "server_clustered: true"; then
            lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
        fi
    fi
else
    cat ./help.txt
fi