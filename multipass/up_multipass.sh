#!/bin/bash

# quit script if anything goes awry
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if there are no multipass environment variables
if [[ -z $(env | grep BCM_MULTIPASS_) ]]; then
  echo "BCM_MULTIPASS_ variables not set. Please source BCM environment variables."
  exit
fi

mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
touch ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml

# if the user has not specified BCM_LXD_SECRET, generate a secure one
if [ ! -f ~/.bcm/endpoints$BCM_MULTIPASS_VM_NAME.env ]; then
  BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)
  touch ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  cat $BCM_LOCAL_GIT_REPO/resources/bcm/default_endpoints/bcm-01.env >> ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  echo "export BCM_LXD_SECRET="$BCM_LXD_SECRET > ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
else
  source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
fi

# update the cloud-init template and save a local copy in ~/.bcm/runtime/...
sed 's/CHANGEME/'$BCM_LXD_SECRET'/g' ./multipass_cloud-init.yml  > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml

## launch the VM based on Ubuntu Bionic
multipass launch \
  --disk $BCM_MULTIPASS_DISK_SIZE \
  --mem $BCM_MULTIPASS_MEM_SIZE \
  --cpus $BCM_MULTIPASS_CPU_COUNT \
  --name $BCM_MULTIPASS_VM_NAME \
  --cloud-init ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml \
  bionic

# #restart the VM for updates to take effect
multipass stop $BCM_MULTIPASS_VM_NAME
multipass start $BCM_MULTIPASS_VM_NAME

# Get the IP address that was given to the multipass VM and add it 
# as a remote LXD endpoint and configure the local client to execute 
# commands against it.
MULTIPASS_VM_IP_ADDRESS=$(multipass list | grep "$BCM_MULTIPASS_VM_NAME" | awk '{ print $3 }')

echo "Waiting for the remote lxd daemon to become avaialable."
wait-for-it -t 0 $MULTIPASS_VM_IP_ADDRESS:8443

echo "Adding a lxd remote for $BCM_MULTIPASS_VM_NAME at $MULTIPASS_VM_IP_ADDRESS:8443."
lxc remote add $BCM_MULTIPASS_VM_NAME "$MULTIPASS_VM_IP_ADDRESS:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote set-default "$BCM_MULTIPASS_VM_NAME"

echo "Current lxd remote default is $BCM_MULTIPASS_VM_NAME."

if [[ $BCM_MULTIPASS_PROVISION_LXD = "true" ]]; then
  echo "Running ./lxd/up_lxc_endpoint.sh against active LXD remote endpoint."
  source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh
  bash -c "$BCM_LOCAL_GIT_REPO/lxd/up_lxc_endpoint.sh"
fi

cd ~/.bcm
git add *
git commit -am "Added ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env and ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME"
cd -