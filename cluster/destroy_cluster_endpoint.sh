#!/bin/bash

set -eu

BCM_CLUSTER_NAME=$1
BCM_CLUSTER_ENDPOINT_NAME=$2

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME not set. Exiting."
  exit
fi

BCM_CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
ENDPOINTS_DIR=$BCM_CLUSTER_DIR/endpoints
BCM_ENDPOINT_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME

echo "BCM_CLUSTER_DIR: $BCM_CLUSTER_DIR"
echo "ENDPOINTS_DIR: $ENDPOINTS_DIR"
echo "BCM_ENDPOINT_DIR: $BCM_ENDPOINT_DIR"

if [[ $(multipass list | grep "$BCM_CLUSTER_ENDPOINT_NAME") ]]; then
  if [[ -f $BCM_ENDPOINT_DIR/.env ]]; then
    source $BCM_ENDPOINT_DIR/.env
  fi
fi

# quit if there are no multipass environment variables loaded.
if [[ -z $(env | grep "$BCM_CLUSTER_ENDPOINT_NAME") ]]; then
  echo "BCM_CLUSTER_ENDPOINT_NAME variable not set."
  exit 1
fi

# Stopping multipass vm $MULTIPASS_VM_NAME
if [[ $(multipass list | grep "$BCM_CLUSTER_ENDPOINT_NAME") ]]; then
  echo "Stopping multipass vm $BCM_CLUSTER_ENDPOINT_NAME"
  sudo multipass stop $BCM_CLUSTER_ENDPOINT_NAME
  sudo multipass delete $BCM_CLUSTER_ENDPOINT_NAME
  sudo multipass purge
else
  echo "$BCM_CLUSTER_ENDPOINT_NAME doesn't exist."
fi

# Removing lxc remote vm
if [[ $(lxc remote list | grep $BCM_CLUSTER_ENDPOINT_NAME) ]]; then
    echo "Removing lxd remote $BCM_CLUSTER_ENDPOINT_NAME"
    lxc remote set-default local
    lxc remote remove $BCM_CLUSTER_ENDPOINT_NAME
else
    echo "No lxc remote called $BCM_CLUSTER_ENDPOINT_NAME to delete."
fi

if [[ -d $BCM_ENDPOINT_DIR ]]; then
  rm -rf $BCM_ENDPOINT_DIR
fi

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh 'Destroyed $BCM_CLUSTER_ENDPOINT_NAME and associated files.'"
