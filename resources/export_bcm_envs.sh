#!/usr/bin/env bash

set -eu

# # let's export the current cluster based on the current LXD remote endpoint.
# export BCM_CLUSTER_NAME=""

# if [[ ! -z $(snap list | grep lxd) ]]; then
#   if [[ $(lxc remote get-default) = "local" ]]; then
#     BCM_CLUSTER_NAME="DEV_MACHINE"
#   else
#     BCM_CLUSTER_NAME=$(lxc info | grep "server_name" | awk 'NF>1{print $NF}')
#   fi

#   if [[ -z $BCM_CLUSTER_NAME ]]; then
#     echo "BCM_CLUSTER_NAME is not defined. Current value is '$BCM_CLUSTER_NAME'"
#     exit
#   fi

#   export BCM_CLUSTER_ENDPOINT_NAME=$(lxc remote get-default)
# fi

# make the hwwallet_certs directory if it doesn't exist.
export BCM_PROJECT_DIR=~/.bcm/projects/$BCM_PROJECT_NAME
if [[ ! -d $BCM_PROJECT_DIR ]]; then
    mkdir -p $BCM_PROJECT_DIR
fi
