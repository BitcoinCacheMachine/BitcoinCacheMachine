#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

COMMAND=${2:-}
if [ ! -z "${COMMAND}" ]; then
    BCM_CLI_VERB="$COMMAND"
else
    echo "Please provide a project command."
    cat ./help.txt
    exit
fi

BCM_PROJECT_NAME=BCMBase
BCM_CLUSTER_NAME="$(lxc remote get-default)"
BCM_DEPLOYMENTS_FLAG=0

for i in "$@"; do
    case $i in
        --project-name=*)
            BCM_PROJECT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --deployments)
            BCM_DEPLOYMENTS_FLAG=1
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_CLI_VERB == "list" ]]; then
    export BCM_DEPLOYMENTS_FLAG=$BCM_DEPLOYMENTS_FLAG
    ./list/list.sh "$@"
    exit
fi

if [[ -z $BCM_PROJECT_NAME ]]; then
    echo "WARNING: BCM_PROJECT_NAME was not specified."
fi

export BCM_PROJECT_NAME="$BCM_PROJECT_NAME"

# call the appropriate sciprt.
if [[ $BCM_CLI_VERB == "create" ]]; then
    ./create/create.sh "$@"
fi

export BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"
if [[ $BCM_CLI_VERB == "deploy" ]]; then
    ./deploy/deploy.sh "$@"
    elif [[ $BCM_CLI_VERB == "remove" ]]; then
    bash -c "$BCM_GIT_DIR/project/destroy.sh" "$@"
fi