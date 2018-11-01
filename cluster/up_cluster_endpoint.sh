#!/bin/bash

# quit script if anything goes awry
set -eu

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if there are no multipass environment variables
if [[ -z $(env | grep BCM_CLUSTER_ENDPOINT_NAME) ]]; then
  echo "BCM_CLUSTER_ENDPOINT_NAME variables not set."
  exit
fi

IS_MASTER=$1
BCM_MULTIPASS_CLUSTER_MASTER=$2
BCM_CLUSTER_ENDPOINT_NAME=$3
BCM_PROVIDER_NAME=$4
BCM_ENDPOINT_VM_IP=

# if there's no .env file for the specified VM, we'll generate a new one.
if [ -f $ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME/.env ]; then
  source $ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME/.env
else
  echo "Error. No $ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME/.env file to source."
  exit
fi

if [[ -z $BCM_PROVIDER_NAME ]]; then
  echo "BCM_PROVIDER_NAME not set. Exiting."
  exit
fi

if [[ $BCM_PROVIDER_NAME = 'lxd' ]]; then
  echo "todo; lxd in up_cluster_endpoint.sh"
elif [[ $BCM_PROVIDER_NAME = "multipass" ]]; then
  ## launch the VM based on Ubuntu Bionic with a static cloud-init.
  # we'll create lxd preseed files AFTER boot so we know the IP address.
  multipass launch \
    --disk $BCM_ENDPOINT_DISK_SIZE \
    --mem $BCM_ENDPOINT_MEM_SIZE \
    --cpus $BCM_ENDPOINT_CPU_COUNT \
    --name $BCM_CLUSTER_ENDPOINT_NAME \
    --cloud-init ./cloud_init.yml \
    bionic

  #restart the VM for updates to take effect
  multipass stop $BCM_CLUSTER_ENDPOINT_NAME
  multipass start $BCM_CLUSTER_ENDPOINT_NAME


  export BCM_ENDPOINT_VM_IP=$(multipass list | grep "$BCM_CLUSTER_ENDPOINT_NAME" | awk '{ print $3 }')

elif [[ $BCM_PROVIDER_NAME = "baremetal" ]]; then
  echo "todo; baremetal in up_cluster_endpoint.sh"
elif [[ $BCM_PROVIDER_NAME = "aws" ]]; then
  echo "todo; aws in up_cluster_endpoint.sh"
fi


# make sure we get a good IP.
if [[ -z $BCM_ENDPOINT_VM_IP ]]; then
    echo "Could not determine the IP address for $BCM_CLUSTER_ENDPOINT_NAME."
    exit
fi

# now we need to create the appropriate cloud-init file now that we have the IP address.
if [[ $IS_MASTER = "true" ]]; then
  bash -c ./provision_lxd_master.sh
else
  bash -c ./provision_lxd_member.sh
fi