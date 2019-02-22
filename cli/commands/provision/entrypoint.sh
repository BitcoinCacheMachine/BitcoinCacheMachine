#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

COMMAND=${1:-}
if [ ! -z "${COMMAND}" ]; then
    BCM_CLI_VERB="$COMMAND"
else
    echo "Please provide a project command."
    cat ./help.txt
    exit
fi

# the base project
BCM_PROJECT_NAME="BCMBase"
BCM_CLUSTER_NAME="$(lxc remote get-default)"
BCM_DELETE_BCM_IMAGE=0
BCM_DELETE_LXC_BASE=0

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --del-template)
            BCM_DELETE_BCM_IMAGE=1
            shift # past argument=value
        ;;
        --del-bcmbase)
            BCM_DELETE_LXC_BASE=1
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if ! lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
    echo "BCM cluster '$BCM_CLUSTER_NAME' not found. Can't deploy project to it."
    exit
fi

if [[ $BCM_CLI_VERB == "provision" ]]; then
    if [[ ! -z "$BCM_PROJECT_NAME" ]]; then
        "$BCM_GIT_DIR/project/up.sh" --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME"
    fi
    
    elif [[ $BCM_CLI_VERB == "deprovision" ]]; then
    bash -c "$BCM_GIT_DIR/project/destroy.sh --project-name=$BCM_PROJECT_NAME --del-template=$BCM_DELETE_BCM_IMAGE --del-bcmbase=$BCM_DELETE_LXC_BASE"
fi