#!/bin/bash

# quit script if anything goes awry
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if there are no multipass environment variables
if [[ -z $(env | grep MULTIPASS) ]]; then
  echo "MULTIPASS_ variables not set. Please source BCM environment variables."
  exit
fi

mkdir -p ~/.bcm/runtime/$MULTIPASS_VM_NAME
touch ~/.bcm/runtime/$MULTIPASS_VM_NAME/cloud-init.yml
sed 's/CHANGEME/'$BCS_LXD_SECRET'/g' ./multipass_cloud-init.yml  > ~/.bcm/runtime/$MULTIPASS_VM_NAME/cloud-init.yml


## launch the VM based on Ubuntu Bionic
multipass launch \
  --disk $MULTIPASS_DISK_SIZE \
  --mem $MULTIPASS_MEM_SIZE \
  --cpus $MULTIPASS_CPU_COUNT \
  -n "$MULTIPASS_VM_NAME" \
  --cloud-init ~/.bcm/runtime/$MULTIPASS_VM_NAME/cloud-init.yml \
  bionic

# #restart the VM for updates to take effect
multipass stop $MULTIPASS_VM_NAME
multipass start $MULTIPASS_VM_NAME

# Get the IP address that was given to the multipass VM and add it 
# as a remote LXD endpoint and configure the local client to execute 
# commands against it.
MULTIPASS_VM_IP_ADDRESS=$(multipass list | grep "$MULTIPASS_VM_NAME" | awk '{ print $3 }')

echo "Waiting for the remote lxd daemon to become avaialable."
wait-for-it -t 0 $MULTIPASS_VM_IP_ADDRESS:8443

echo "Adding a lxd remote for $MULTIPASS_VM_NAME at $MULTIPASS_VM_IP_ADDRESS:8443."
lxc remote add $MULTIPASS_VM_NAME "$MULTIPASS_VM_IP_ADDRESS:8443" --accept-certificate --password="$BCS_LXD_SECRET"
lxc remote set-default "$MULTIPASS_VM_NAME"

echo "Current lxd remote default is $MULTIPASS_VM_NAME."

if [[ $MULTIPASS_PROVISION_LXD = "true" ]]; then
  echo "Running ./lxd/up.sh against active LXD remote endpoint."
  bash -c ./lxd/up_bcs_bcm.sh
fi