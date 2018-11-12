#!/bin/bash

set -eu
cd "$(dirname "$0")"

for i in "$@"
do
case $i in
    --remove-template)
    BCM_REMOVE_TEMPLATE_FLAG=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


BCM_DEPLOYMENT_DIR=$BCM_DEPLOYMENTS_DIR/$BCM_PROJECT_NAME"_"$BCM_CLUSTER_NAME
if [[ ! -d $BCM_DEPLOYMENT_DIR ]]; then
    echo "BCM Deployment directory '$BCM_DEPLOYMENT_DIR' does not exist. Exiting"
    exit
fi

export BCM_REMOVE_TEMPLATE_FLAG=$BCM_REMOVE_TEMPLATE_FLAG

source $BCM_LOCAL_GIT_REPO_DIR/lxd/defaults.sh

$BCM_LOCAL_GIT_REPO_DIR/lxd/bcm_project_destroy.sh --remove-template

if [[ -d $BCM_DEPLOYMENT_DIR ]]; then
    sudo rm -Rf $BCM_DEPLOYMENT_DIR
fi