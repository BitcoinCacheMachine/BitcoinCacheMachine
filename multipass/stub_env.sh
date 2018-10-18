#!/bin/bash

TYPE=$1

# create the file
ENV_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME/endpoints/$BCM_MULTIPASS_VM_NAME
mkdir -p $ENV_DIR

ENV_FILE="$ENV_DIR/.env"
touch $ENV_FILE

# generate an LXD secret for the new VM lxd endpoint.
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

if [ $TYPE = "master" ]; then
    envsubst < ./env/multipass_master_defaults.env > $ENV_FILE
elif [ $TYPE = "member" ]; then
    envsubst < ./env/multipass_member_defaults.env > $ENV_FILE
else
    echo "Incorrect usage. Please specify whether $BCM_MULTIPASS_VM_NAME is an LXD cluster master or member."
fi

bash -c "$BCM_LOCAL_GIT_REPO/resources/commit_bcm.sh"