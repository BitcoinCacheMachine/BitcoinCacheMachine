#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_HELP_FLAG=0
if [[ -z $2 ]]; then
    BCM_HELP_FLAG=1
fi

BCM_CLI_VERB=$2
BCM_CLUSTER_NAME=
BCM_PROVIDER_NAME=
BCM_NODE_COUNT=
BCM_ENDPOINTS_FLAG=0

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --provider=*)
            BCM_PROVIDER_NAME="${i#*=}"
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
    bash -c "$BCM_GIT_DIR/cluster/up_cluster.sh \
        --cluster-name=$BCM_CLUSTER_NAME \
        --node-count=$BCM_NODE_COUNT \
    --provider=$BCM_PROVIDER_NAME"
    
    elif [[ $BCM_CLI_VERB == "destroy" ]]; then
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    bash -c "$BCM_GIT_DIR/cluster/destroy_cluster.sh --cluster-name=$BCM_CLUSTER_NAME"
    elif [[ $BCM_CLI_VERB == "list" ]]; then
    
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    
    # shellcheck disable=SC2153
    export BCM_CLUSTER_DIR="$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME"
    export BCM_ENDPOINTS_FLAG=$BCM_ENDPOINTS_FLAG
    
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
    else
        if [[ -d $BCM_CLUSTERS_DIR ]]; then
            find "$BCM_CLUSTERS_DIR/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -v ".git"
        fi
    fi
else
    cat ./help.txt
fi
