#!/bin/bash

cd "$(dirname "$0")"

set -eu

BCM_CLUSTER_NAME=

for i in "$@"
do
case $i in
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
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

if [[ ! -d ~/.bcm/clusters/$BCM_CLUSTER_NAME ]]; then
  echo "~/.bcm/clusters/$BCM_CLUSTER_NAME does not exist. Nothing to destroy."
  exit
fi

if [[ $BCM_DEBUG = 1 ]]; then
  echo "Running destroy_cluster.sh with the following parameters:"
  echo "BCM_CLUSTER_NAME: $BCM_CLUSTER_NAME"
  echo "BCM_CLUSTER_NAME: $BCM_CLUSTER_NAME"
fi

echo "Destroying BCM Cluster '$BCM_CLUSTER_NAME'"
export BCM_CLUSTER_DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
export ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"

if [[ $BCM_DEBUG = 1 ]]; then
  echo "BCM_CLUSTER_DIR: $BCM_CLUSTER_DIR"
  echo "ENDPOINTS_DIR: $ENDPOINTS_DIR"
fi

for endpoint in `bcm cluster list -c=$BCM_CLUSTER_NAME --endpoints`; do
  bash -c "./destroy_cluster_endpoint.sh --cluster-name=$BCM_CLUSTER_NAME --endpoint-name=$endpoint"
done

if [[ $(lxc remote list | grep $BCM_CLUSTER_NAME) ]]; then
  lxc remote set-default local
  lxc remote remove $BCM_CLUSTER_NAME
fi

if [ -d $BCM_CLUSTER_DIR ]; then
  rm -rf $BCM_CLUSTER_DIR
fi

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh --git-commit-message='Destroyed cluster $BCM_CLUSTER_NAME and all associated files.'"
