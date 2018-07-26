#!/bin/bash

# quit script if anything goes awry
set -e 

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get multipass vm parameters.
source ~/.bcm/multipass.env.sh

# quit if there are no multipass environment variables
if [[ $(env | grep MULTIPASS_) = '' ]] 
then
  echo "BCM variables not set. Please source a .env file."
  exit 1
fi

sed 's/CHANGEME/'$BC_LXD_SECRET'/g' ./multipass_cloud-init.yml  > ~/.bcs/multipass_cloud-init-runtime.yml

## launch the VM based on Ubuntu Bionic
multipass launch \
  --disk $MULTIPASS_DISK_SIZE \
  --mem $MULTIPASS_MEM_SIZE \
  --cpus $MULTIPASS_CPU_COUNT \
  -n $MULTIPASS_VM_NAME \
  --cloud-init ~/.bcs/multipass_cloud-init-runtime.yml \
  bionic

#restart the VM for updates to take effect
#multipass stop $MULTIPASS_VM_NAME
#multipass start $MULTIPASS_VM_NAME

# Get the IP address that was given to the multipass VM and add it 
# as a remote LXD endpoint and configure the local client to execute 
# commands against it.
MULTIPASS_VM_IP_ADDRESS=$(multipass list | grep $MULTIPASS_VM_NAME | awk '{ print $3 }')

echo "Waiting for the remote lxd daemon to become avaialble."
wait-for-it -t 0 $MULTIPASS_VM_IP_ADDRESS:8443

lxc remote add $MULTIPASS_VM_NAME $MULTIPASS_VM_IP_ADDRESS:8443 --accept-certificate --password=$BC_LXD_SECRET
lxc remote set-default $MULTIPASS_VM_NAME

# execute the up_lxd.sh script to begin deployment of Cache Stack to the remote LXD API.
bash -c ./lxd/up.sh