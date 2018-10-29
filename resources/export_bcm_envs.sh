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

#   export BCM_MULTIPASS_VM_NAME=$(lxc remote get-default)
# fi


# # make the hwwallet_certs directory if it doesn't exist.
# export BCM_PROJECT_DIR=~/.bcm/projects/$BCM_CURRENT_PROJECT_NAME
# if [[ ! -d $BCM_PROJECT_DIR ]]; then
#     mkdir -p $BCM_PROJECT_DIR
# fi


# # export some variables yo
# export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME

# export BCM_CLUSTER_ROOT_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
# export BCM_CLUSTER_PROJECTS_ROOT_DIR=$BCM_CLUSTER_ROOT_DIR/projects
# export BCM_ENDPOINT_LXD_ROOT_DIR=$BCM_CLUSTER_ROOT_DIR/lxd_endpoints

# if [[ ! -z $(snap list | grep lxd) ]]; then
#   export BCM_ENDPOINT_ROOT_DIR=$BCM_ENDPOINT_LXD_ROOT_DIR/$(lxc remote get-default)
# fi