#!/bin/bash

# quit script if anything goes awry
set -eu

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if there are no multipass environment variables
if [[ -z $(env | grep BCM_MULTIPASS_VM_NAME) ]]; then
  echo "BCM_MULTIPASS_VM_NAME variables not set."
  exit
fi

IS_MASTER=$1
BCM_MULTIPASS_CLUSTER_MASTER=$2
BCM_MULTIPASS_VM_NAME=$3

mkdir -p $ENDPOINTS_DIR

if [[ -z $IS_MASTER ]]; then
  echo "Incorrect usage. Usage: ./up_multipass.sh [ISMASTER] [MASTER]"
  echo "  If ISMASTER=true, the $BCM_MULTIPASS_VM_NAME will be provisioned as the LXD cluster master."
  echo "  If ISMASTER=false, you MUST provide the name of the LXD cluster master."
  exit
fi

# if there's no .env file for the specified VM, we'll generate a new one.
if [ -f $ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME/.env ]; then
  source $ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME/.env
else
  echo "Error. No $ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME/.env file to source."
  exit
fi

#### Update parameters in the 
mkdir -p /tmp/bcm

## launch the VM based on Ubuntu Bionic with a static cloud-init.
# we'll create lxd preseed files AFTER boot so we know the IP address.
multipass launch \
  --disk $BCM_MULTIPASS_DISK_SIZE \
  --mem $BCM_MULTIPASS_MEM_SIZE \
  --cpus $BCM_MULTIPASS_CPU_COUNT \
  --name $BCM_MULTIPASS_VM_NAME \
  --cloud-init ./cloud_init.yml \
  bionic

#restart the VM for updates to take effect
#multipass stop $BCM_MULTIPASS_VM_NAME
#multipass start $BCM_MULTIPASS_VM_NAME

export BCM_MULTIPASS_VM_IP=$(multipass list | grep "$BCM_MULTIPASS_VM_NAME" | awk '{ print $3 }')

# make sure we get a good IP.
if [ -z $BCM_MULTIPASS_VM_IP ]; then
    echo "Could not determine the IP address for $BCM_MULTIPASS_VM_NAME."
    exit
fi

# now we need to create the appropriate cloud-init file now that we have the IP address.
if [[ $IS_MASTER = "true" ]]; then
  bash -c ./provision_lxd_master.sh
else
  bash -c ./provision_lxd_member.sh
fi

bash -c "$BCM_LOCAL_GIT_REPO/resources/commit_bcm.sh"