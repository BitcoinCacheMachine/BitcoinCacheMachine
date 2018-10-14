#!/bin/bash

# quit script if anything goes awry
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if there are no multipass environment variables
if [[ -z $(env | grep BCM_MULTIPASS_VM_NAME) ]]; then
  echo "BCM_MULTIPASS_VM_NAME variables not set. e.g.,  export BCM_MULTIPASS_VM_NAME="'"bcm-01"'""
  exit
fi

IS_MASTER=$1
MASTER=$2
BCM_MULTIPASS_VM_NAME=$3

if [[ -z $IS_MASTER ]]; then
  echo "Incorrect usage. Usage: ./up_multipass.sh [ISMASTER] [MASTER]"
  echo "  If ISMASTER=true, the $BCM_MULTIPASS_VM_NAME will be provisioned as the LXD cluster master."
  echo "  If ISMASTER=false, you MUST provide the name of the LXD cluster master."
  exit
fi

# if there's no .env file for the specified VM, we'll generate a new one.
if [ ! -f ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env ]; then
  bash -c ./stub_env.sh
  source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
fi

#### Update parameters in the 
mkdir -p /tmp/bcm
mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
touch ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml


## launch the VM based on Ubuntu Bionic
multipass launch \
  --disk $BCM_MULTIPASS_DISK_SIZE \
  --mem $BCM_MULTIPASS_MEM_SIZE \
  --cpus $BCM_MULTIPASS_CPU_COUNT \
  --name $BCM_MULTIPASS_VM_NAME \
  --cloud-init ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml \
  bionic

#restart the VM for updates to take effect
#multipass stop $BCM_MULTIPASS_VM_NAME
#multipass start $BCM_MULTIPASS_VM_NAME

#sleep 10

# note that we omit the '--' since we want the entire command (cat and after) to be executed within the multipass shell
#multipass exec $BCM_MULTIPASS_VM_NAME -- sh -c "(cat /etc/lxd/preseed.yml | sudo lxd init --preseed)"

# Get the IP address that was given to the multipass VM and add it 
# as a remote LXD endpoint and configure the local client to execute 
# commands against it.
VM_IP_ADDRESS=$(multipass list | grep "$BCM_MULTIPASS_VM_NAME" | awk '{ print $3 }')

# if there's no .env file for the specified VM, we'll generate a new one.
if [ -z $ ]; then
  echo "Could not determine the IP address for $BCM_MULTIPASS_VM_NAME."
  exit
fi

echo "Waiting for the remote lxd daemon to become available."
wait-for-it -t 0 $VM_IP_ADDRESS:8443

echo "Adding a lxd remote for $BCM_MULTIPASS_VM_NAME at $VM_IP_ADDRESS:8443."
lxc remote add $BCM_MULTIPASS_VM_NAME "$VM_IP_ADDRESS:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote set-default $BCM_MULTIPASS_VM_NAME

echo "Current lxd remote default is $BCM_MULTIPASS_VM_NAME."

if [[ $IS_MASTER == "true" ]]; then
  # lets' get the resulting cluster certificate fingerprint and store it in the .env for the cluster master.
  mkdir -p ~/.bcm/certs/$BCM_MULTIPASS_VM_NAME
  # save the master cluster certificate to the admin machine
  lxc info | grep -zoPe '--BEGIN.*\n\K[^-]+' | head -c-1 > ~/.bcm/certs/$BCM_MULTIPASS_VM_NAME/lxd.cert
  # -- cat /var/lib/lxd/server.crt >> ~/.bcm/certs/$BCM_MULTIPASS_VM_NAME/lxd.cert
elif [[ $IS_MASTER == "false" ]]; then
  # then we're provisioning a cluster member. Let's check to ensure we have info about the master
  if [[ ! -f ~/.bcm/endpoints/$MASTER.env ]]; then
    # Now let's work on creating the cloud-init file.
    bash -c "./stub_cloud-init.sh member"
  else
    echo "~/.bcm/endpoints/$MASTER.env doesn't exist. Can't provision the cluster member."
  fi
else
  echo "Please provide argument 'true' or 'false' to indicate whether the multipass VM is to be a cluster master."
  exit
fi


cd ~/.bcm
git add *
git commit -am "Added ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env and ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME"
cd -

# # # # if [[ $BCM_MULTIPASS_PROVISION_LXD = "true" ]]; then
# # # #   echo "Running ./lxd/up_lxc_endpoint.sh against active LXD remote endpoint."
# # # #   source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh
# # # #   bash -c "$BCM_LOCAL_GIT_REPO/lxd/up_lxc_endpoint.sh"
# # # # fi
