#!/bin/bash

#echo "Sourcing all BCM default environment variables located in $BCM_LOCAL_GIT_REPO/resources/defaults/"

BCM_DEFAULTS_DIR="$BCM_LOCAL_GIT_REPO/resources/bcm/defaults"

source $BCM_DEFAULTS_DIR/defaults.env
source $BCM_DEFAULTS_DIR/gateway.env
source $BCM_DEFAULTS_DIR/managers.env
source $BCM_DEFAULTS_DIR/bitcoin.env

BCM_ACTIVE_LXD_ENDPOINT=$(lxc remote get-default)

ENV_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME/endpoints/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME

# if $ENV_DIR/.env exists, source it
if [[ -e $ENV_DIR/.env ]]; then
    source $ENV_DIR/.env
fi