#!/usr/bin/env bash

BCM_DEFAULTS_DIR="$BCM_LOCAL_GIT_REPO/resources/env_defaults"

source $BCM_DEFAULTS_DIR/defaults.env
source $BCM_DEFAULTS_DIR/gateway.env
# source $BCM_DEFAULTS_DIR/managers.env
# source $BCM_DEFAULTS_DIR/bitcoin.env

# let's export the current cluster based on the current LXD remote endpoint.
BCM_CLUSTER_NAME=""

if [[ $(lxc remote get-default) = "local" ]]; then
  BCM_CLUSTER_NAME="DEV_MACHINE"
else
  BCM_CLUSTER_NAME=$(lxc info | grep "server_name" | awk 'NF>1{print $NF}')
fi

if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME is not defined. Current value is '$BCM_CLUSTER_NAME'"
  exit
fi

# used in certificate generation and selection in dev_machine/trezor
export BCM_CURRENT_PROJECT_NAME="bcm-dev"

# we'll leave this value as-is.
if [[ -z $BCM_PROJECT_CERTIFICATE_EMAIL ]]; then
  export BCM_PROJECT_CERTIFICATE_EMAIL="bcm@devmachine.tld"
fi

# export some variables yo
export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
export BCM_MULTIPASS_VM_NAME=$(lxc remote get-default)
export BCM_CLUSTER_ROOT_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
export BCM_CLUSTER_PROJECTS_ROOT_DIR=$BCM_CLUSTER_ROOT_DIR/lxd_projects
export BCM_ENDPOINT_LXD_ROOT_DIR=$BCM_CLUSTER_ROOT_DIR/lxd_endpoints
export BCM_ENDPOINT_ROOT_DIR=$BCM_ENDPOINT_LXD_ROOT_DIR/$(lxc remote get-default)
