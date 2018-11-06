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
BCM_SHOW_ENDPOINTS_FLAG=0

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
    BCM_SHOW_ENDPOINTS_FLAG=1
    shift # past argument=value
    ;;


    *)
    ;;
esac
done

# of the CLI OBJECT is not set, show help
if [[ -z $BCM_CLI_OBJECT ]]; then
    BCM_HELP_FLAG=1
fi
# call the appropriate sciprt.
if [[ $BCM_CLI_VERB = "create" ]]; then

    export BCM_PROJECT_NAME=$BCM_CLI_OBJECT
    export BCM_PROJECT_USERNAME=$BCM_PROJECT_USERNAME
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    
    bash -c ./create/create.sh
elif [[ $BCM_CLI_VERB = "destroy" ]]; then
    export BCM_PROJECT_NAME=$BCM_CLI_OBJECT
    env BCM_FORCE_FLAG=$BCM_FORCE_FLAG bash -c ./destroy/destroy.sh
elif [[ $BCM_CLI_VERB = "get-default" ]]; then
    export BCM_DIRECTORY_FLAG=$BCM_DIRECTORY_FLAG
    bash -c ./getdefault/getdefault.sh
elif [[ $BCM_CLI_VERB = "set-default" ]]; then
    export BCM_NEW_PROJECT_NAME=$BCM_CLI_OBJECT
    bash -c ./setdefault/setdefault.sh
elif [[ $BCM_CLI_VERB = "list" ]]; then
    bash -c ./list/list.sh "$@"
elif [[ $BCM_CLI_VERB = "deploy" ]]; then
    bash -c ./deploy/deploy.sh "$@"
else
    BCM_HELP_FLAG=1
fi

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
fi