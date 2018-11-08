#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_CLUSTER_NAME=
BCM_CLUSTER_ENDPOINT_NAME=
BCM_REMOVE_SOFTWARE=0

for i in "$@"
do
case $i in
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --endpoint-name=*)
    BCM_CLUSTER_ENDPOINT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --remove-software)
    BCM_REMOVE_SOFTWARE=1
    shift # past argument=value
    ;;
    *)

    ;;
esac
done

if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME not set. Exiting."
  exit
fi

BCM_CLUSTER_DIR=$BCM_RUNTIME_DIR/clusters/$BCM_CLUSTER_NAME
ENDPOINTS_DIR=$BCM_CLUSTER_DIR/endpoints
BCM_ENDPOINT_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME

if [[ $BCM_DEBUG = 1 ]]; then
  echo "BCM_CLUSTER_DIR: $BCM_CLUSTER_DIR"
  echo "ENDPOINTS_DIR: $ENDPOINTS_DIR"
  echo "BCM_ENDPOINT_DIR: $BCM_ENDPOINT_DIR"
fi

function deleteLXDRemote {
  # Removing lxc remote vm
  if [[ ! -z $(lxc remote list | grep "$BCM_CLUSTER_ENDPOINT_NAME") ]]; then
      echo "Removing lxd remote $BCM_CLUSTER_ENDPOINT_NAME"
      lxc remote set-default local
      lxc remote remove $BCM_CLUSTER_ENDPOINT_NAME
  fi
}

if [[ ! -f $BCM_ENDPOINT_DIR/.env ]]; then
  echo "No $BCM_ENDPOINT_DIR/.env file exists to source. Cannot delete endpoint."
  deleteLXDRemote
  exit
fi

source $BCM_ENDPOINT_DIR/.env

# Ensure the endpoint name is in our env.
if [[ -z $(env | grep "$BCM_CLUSTER_ENDPOINT_NAME") ]]; then
  echo "BCM_CLUSTER_ENDPOINT_NAME variable not set."
  exit 1
fi

if [[ $BCM_PROVIDER_NAME = "multipass" ]]; then
  # Stopping multipass vm $MULTIPASS_VM_NAME
  if [[ $(multipass list | grep "$BCM_CLUSTER_ENDPOINT_NAME") ]]; then
    echo "Stopping multipass vm $BCM_CLUSTER_ENDPOINT_NAME"
    sudo multipass stop $BCM_CLUSTER_ENDPOINT_NAME
    sudo multipass delete $BCM_CLUSTER_ENDPOINT_NAME
    sudo multipass purge
    deleteLXDRemote
  else
    echo "$BCM_CLUSTER_ENDPOINT_NAME doesn't exist."
  fi
elif [[ $BCM_PROVIDER_NAME = "baremetal" ]]; then
    echo "Removing LXD from your system."
    deleteLXDRemote

    if [[ ! -z $(lxc profile list | grep "bcm_default") ]]; then
      lxc profile delete bcm_default
    fi
fi

if [[ -d $BCM_ENDPOINT_DIR ]]; then
  rm -rf $BCM_ENDPOINT_DIR
fi
