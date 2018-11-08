#!/bin/bash

set -e
cd "$(dirname "$0")"

BCM_HELP_FLAG=0
if [[ -z $2 ]]; then
    BCM_HELP_FLAG=1
fi

BCM_CLI_VERB=$2
BCM_CLUSTER_NAME=
BCM_PROVIDER_NAME=
BCM_MGMT_TYPE=
BCM_NODE_COUNT=
BCM_ENDPOINTS_FLAG=0
BCM_SHOW_DEPLOYMENTS_FLAG=0

for i in "$@"
do
case $i in
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
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
    --node-count=*)
    BCM_NODE_COUNT="${i#*=}"
    shift # past argument=value
    ;;
    --endpoints)
    BCM_ENDPOINTS_FLAG=1
    shift # past argument=value
    ;;
    --endpoints)
    BCM_SHOW_DEPLOYMENTS_FLAG=1
    shift # past argument=value
    ;;

    *)
    ;;
esac
done

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ $BCM_CLI_VERB = "create" ]]; then

    if [[ !($BCM_MGMT_TYPE = "local" || $BCM_MGMT_TYPE = "tor") ]]; then
        echo "Error. BCM_MGMT_TYPE should be either 'local' or 'tor'."
        cat ./create/help.txt
        exit
    fi

    bash -c "$BCM_LOCAL_GIT_REPO_DIR/cluster/up_cluster.sh --cluster-name=$BCM_CLUSTER_NAME --node-count=$BCM_NODE_COUNT --provider=$BCM_PROVIDER_NAME --mgmt-type=$BCM_MGMT_TYPE"
elif [[ $BCM_CLI_VERB = "destroy" ]]; then
    if [[ -z $BCM_CLUSTER_NAME ]]; then
        echo "BCM_CLUSTER_NAME not set. Exiting"
        exit
    fi

    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/cluster/destroy_cluster.sh --cluster-name="$BCM_CLUSTER_NAME""
elif [[ $BCM_CLI_VERB = "list" ]]; then
    
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    export BCM_CLUSTER_DIR=$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME
    export BCM_ENDPOINTS_FLAG=$BCM_ENDPOINTS_FLAG

    bash -c ./list/list.sh
else
    cat ./help.txt
fi