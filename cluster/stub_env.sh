#!/bin/bash

set -eu


cd "$(dirname "$0")"

echo "in stub_env.sh"
echo "BCM_BCM_CLUSTER_DIR: $BCM_BCM_CLUSTER_DIR"
echo "BCM_CLUSTER_ENDPOINT_NAME: $BCM_CLUSTER_ENDPOINT_NAME"

export BCM_CLUSTER_ENDPOINT_TYPE=$1
export BCM_PROVIDER_NAME=$2

echo "BCM_CLUSTER_ENDPOINT_TYPE: $BCM_CLUSTER_ENDPOINT_TYPE"
# create the file
ENV_DIR=$BCM_BCM_CLUSTER_DIR/endpoints/$BCM_CLUSTER_ENDPOINT_NAME
mkdir -p $ENV_DIR

ENV_FILE="$ENV_DIR/.env"
touch $ENV_FILE

# generate an LXD secret for the new VM lxd endpoint.
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

if [ $BCM_CLUSTER_ENDPOINT_TYPE = "master" ]; then
    envsubst < ./providers/$BCM_PROVIDER_NAME/env/master_defaults.env > $ENV_FILE
elif [ $BCM_CLUSTER_ENDPOINT_TYPE = "member" ]; then
    envsubst < ./providers/$BCM_PROVIDER_NAME/env/member_defaults.env > $ENV_FILE
else
    echo "Incorrect usage. Please specify whether $BCM_CLUSTER_ENDPOINT_NAME is an LXD cluster master or member."
fi

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh 'Added files associated with stub_env.sh'"