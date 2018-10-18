#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

VM_NAME=$1
export BCM_MULTIPASS_VM_NAME=$VM_NAME

CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
ENDPOINTS_DIR=$CLUSTER_DIR/endpoints
VM_DIR=$ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME

echo "CLUSTER_DIR=$CLUSTER_DIR"
echo "ENDPOINTS_DIR=$ENDPOINTS_DIR"
echo "VM_DIR=$VM_DIR"

if [[ $(multipass list | grep $VM_NAME) ]]; then
  if [[ -f $VM_DIR/.env ]]; then
    source $VM_DIR/.env
  fi
fi

# quit if there are no multipass environment variables loaded.
if [[ -z $(env | grep "BCM_MULTIPASS_VM_NAME") ]]; then
  echo "BCM_MULTIPASS_VM_NAME variable not set."
  exit 1
fi

# Stopping multipass vm $MULTIPASS_VM_NAME
if [[ $(multipass list | grep "$BCM_MULTIPASS_VM_NAME") ]]; then
  echo "Stopping multipass vm $BCM_MULTIPASS_VM_NAME"
  sudo multipass stop $BCM_MULTIPASS_VM_NAME
  sudo multipass delete $BCM_MULTIPASS_VM_NAME
  sudo multipass purge
else
  echo "$BCM_MULTIPASS_VM_NAME doesn't exist."
fi

# Removing lxc remote vm
if [[ $(lxc remote list | grep $BCM_MULTIPASS_VM_NAME) ]]; then
    echo "Removing lxd remote $BCM_MULTIPASS_VM_NAME"
    lxc remote set-default local
    lxc remote remove $BCM_MULTIPASS_VM_NAME
else
    echo "No lxc remote called $BCM_MULTIPASS_VM_NAME to delete."
fi

if [[ -d $VM_DIR ]]; then
  rm -rf $VM_DIR
fi

if [[ -d /tmp/bcm ]]; then
  rm -rf /tmp/bcm
fi

bash -c "$BCM_LOCAL_GIT_REPO/resources/commit_bcm.sh"
