#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_HELP_FLAG=0
if [[ -z $2 ]]; then
    BCM_HELP_FLAG=1
fi

BCM_CLI_VERB=$2
BCM_PROJECT_NAME=
BCM_CLUSTER_NAME=
BCM_FORCE_FLAG=0
BCM_DEPLOYMENTS_FLAG=0

for i in "$@"
do
case $i in
    --project-name=*)
    BCM_PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --force)
    BCM_FORCE_FLAG=1
    shift # past argument=value
    ;;
    --deployments)
    BCM_DEPLOYMENTS_FLAG=1
    shift # past argument=value
    ;;
    *)
    ;;
esac
done


# call the appropriate sciprt.
if [[ $BCM_CLI_VERB = "create" ]]; then
    if [[ -z $BCM_PROJECT_NAME ]]; then
        echo "Error: BCM_PROJECT_NAME is required."
        cat ./$BCM_CLI_VERB/help.txt
        exit
    fi

    export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
    ./create/create.sh "$@"
elif [[ $BCM_CLI_VERB = "destroy" ]]; then
    if [[ -z $BCM_PROJECT_NAME ]]; then
        echo "Error: BCM_PROJECT_NAME is required."
        cat ./$BCM_CLI_VERB/help.txt
        exit
    fi
    
    export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
    export BCM_FORCE_FLAG=$BCM_FORCE_FLAG

    ./destroy/destroy.sh "$@"
elif [[ $BCM_CLI_VERB = "list" ]]; then
    export BCM_DEPLOYMENTS_FLAG=$BCM_DEPLOYMENTS_FLAG
    ./list/list.sh "$@"
elif [[ $BCM_CLI_VERB = "deploy" ]]; then
    if [[ -z $BCM_PROJECT_NAME ]]; then
        echo "Error: BCM_PROJECT_NAME is required."
        cat ./$BCM_CLI_VERB/help.txt
        exit
    fi

    if [[ -z $BCM_CLUSTER_NAME ]]; then
        echo "Error: BCM_CLUSTER_NAME is required."
        cat ./$BCM_CLI_VERB/help.txt
        exit
    fi
    
    export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    export BCM_FORCE_FLAG=$BCM_FORCE_FLAG
    ./deploy/deploy.sh "$@"
elif [[ $BCM_CLI_VERB = "undeploy" ]]; then
    if [[ -z $BCM_PROJECT_NAME ]]; then
        echo "Error: BCM_PROJECT_NAME is required."
        cat ./$BCM_CLI_VERB/help.txt
        exit
    fi

    if [[ -z $BCM_CLUSTER_NAME ]]; then
        echo "Error: BCM_CLUSTER_NAME is required."
        cat ./$BCM_CLI_VERB/help.txt
        exit
    fi
    
    export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    export BCM_FORCE_FLAG=$BCM_FORCE_FLAG
    ./undeploy/undeploy.sh "$@"
else
    BCM_HELP_FLAG=1
fi

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
fi