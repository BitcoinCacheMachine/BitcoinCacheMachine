#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"
 
source ./.env

# let's make sure the cluster exists.
if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME not set."
  exit
fi 

# let's make sure the cluster exists.
if [[ -z $BCM_PROJECT_NAME ]]; then
  echo "BCM_PROJECT_NAME not set."
  exit
fi

# let's make sure the cluster exists.
if [[ -z $BCM_CLUSTER_DIR ]]; then
  echo "BCM_CLUSTER_DIR not set."
  exit
fi 


# exit if the cluster definition is missing
if ! bcm cluster list | grep -q "$BCM_CLUSTER_NAME"; then
  echo "Cluster '$BCM_CLUSTER_NAME' does not exist. BCM Project '$BCM_PROJECT_NAME' will not be deployed."
  exit
fi

# Exit if the project already exists.
if ! bcm project list | grep -q "$BCM_PROJECT_NAME"; then
  echo "Project '$BCM_PROJECT_NAME' does not exist. Can't deploy."
  exit
fi

if [[ $(lxc remote get-default) != "$BCM_CLUSTER_NAME" ]]; then
    if ! lxc remote list | grep -q "$BCM_CLUSTER_NAME"; then
      echo "Changing the default LXD client remote to BCM cluster '$BCM_CLUSTER_NAME'."
      lxc remote switch "$BCM_CLUSTER_NAME"
    fi
fi

# make sure we're on the right remove
if ! lxc project list | grep -q "$BCM_PROJECT_NAME"; then
    lxc project create "$BCM_PROJECT_NAME" -c features.images=false -c features.profiles=false
    lxc project switch "$BCM_PROJECT_NAME"
else
    echo "LXC project '$BCM_PROJECT_NAME' already exists."
fi

export BCM_LXD_OPS=$BCM_LXD_OPS


# This brings up 'bcm-gateway' and 'bcm-kafka' LXC hosts and populates
# the respective docker daemons.


if [[ $BCM_DEPLOY_HOST_TEMPLATE = 1 ]]; then
  ./host_template/destroy.sh
fi

bash -c ./host_template/up.sh

if [[ $BCM_DEPLOY_TIERS = 1 ]]; then
  # All tiers require that the bcm-template image be available.
  # let's look for it before we even attempt anything.
  if lxc image list --format csv | grep -q "bcm-template"; then
    bash -c ./tiers/up.sh
  else
    echo "LXC image 'bcm-template' doesn't exist. Can't deploy BCM tiers."
  fi
fi 