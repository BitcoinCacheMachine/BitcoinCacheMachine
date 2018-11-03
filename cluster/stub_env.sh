#!/bin/bash

set -eu


cd "$(dirname "$0")"

BCM_CLUSTER_ENDPOINT_NAME=$1
BCM_CLUSTER_ENDPOINT_TYPE=$2
BCM_ENDPOINT_DIR=$3

if [[ $BCM_DEBUG = 1 ]]; then
    echo "BCM_CLUSTER_ENDPOINT_NAME: $BCM_CLUSTER_ENDPOINT_NAME"
    echo "BCM_CLUSTER_ENDPOINT_TYPE: $BCM_CLUSTER_ENDPOINT_TYPE"
    echo "BCM_ENDPOINT_DIR: $BCM_ENDPOINT_DIR"
fi

# create the file
mkdir -p $BCM_ENDPOINT_DIR
ENV_FILE=$BCM_ENDPOINT_DIR/.env
touch $ENV_FILE

# generate an LXD secret for the new VM lxd endpoint.
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

if [ $BCM_CLUSTER_ENDPOINT_TYPE = "master" ]; then
    envsubst < ./env/master_defaults.env > $ENV_FILE
elif [ $BCM_CLUSTER_ENDPOINT_TYPE = "member" ]; then
    envsubst < ./env/member_defaults.env > $ENV_FILE
else
    echo "Incorrect usage. Please specify whether $BCM_CLUSTER_ENDPOINT_NAME is an LXD cluster master or member."
fi

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh 'Added files associated with stub_env.sh'"