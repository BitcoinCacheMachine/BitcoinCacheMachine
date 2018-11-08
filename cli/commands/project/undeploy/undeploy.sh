#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_PROJECT_NAME=
BCM_CLUSTER_NAME=

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
    --user-name=*)
    BCM_PROJECT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done



if [[ -z $(bcm cluster list | grep "$BCM_CLUSTER_NAME") ]]; then
    echo "BCM cluster '$BCM_CLUSTER_NAME' not found. Can't undeploy any projects."
    exit
fi

BCM_DEPLOYMENT_DIR="$BCM_DEPLOYMENTS_DIR/$BCM_PROJECT_NAME"'_'"$BCM_CLUSTER_NAME"
if [[ ! -d $BCM_DEPLOYMENTS_DIR ]]; then
    echo "BCM Deployment directory '$BCM_DEPLOYMENT_DIR' does not exist. Exiting"
    exit
fi

export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME

source $BCM_LOCAL_GIT_REPO_DIR/lxd/defaults.sh

$BCM_LOCAL_GIT_REPO_DIR/lxd/bcm_project_destroy.sh --remove-template

if [[ -d $BCM_DEPLOYMENT_DIR ]]; then
    sudo rm -Rf $BCM_DEPLOYMENT_DIR
fi