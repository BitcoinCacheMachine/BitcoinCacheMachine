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
  if [[ ! -f ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml ]]; then  
    # substitute the variables in lxd_master_preseed.yml
    mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
    envsubst < ./lxd_preseed/lxd_master_preseed.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/lxd_preseed.yml

    # upload the lxd preseed file to the multipass vm.
    multipass copy-files ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/lxd_preseed.yml $BCM_MULTIPASS_VM_NAME:/home/multipass/preseed.yml

    # now initialize the LXD daemon on the VM.
    multipass exec $BCM_MULTIPASS_VM_NAME -- sh -c "cat /home/multipass/preseed.yml | sudo lxd init --preseed"

    # since it's the master, let's grab the certificate so we can use it in subsequent lxd_pressed files.
    if [[ ! -f ~/.bcm/certs/$BCM_MULTIPASS_VM_NAME/lxd.cert ]]; then
      # lets' get the resulting cluster certificate fingerprint and store it in the .env for the cluster master.
      mkdir -p ~/.bcm/certs/$BCM_MULTIPASS_VM_NAME
      multipass exec $BCM_MULTIPASS_VM_NAME -- cat /var/snap/lxd/common/lxd/server.crt >> ~/.bcm/certs/$BCM_MULTIPASS_VM_NAME/lxd.cert
    fi

    echo "Waiting for the remote lxd daemon to become available."
    wait-for-it -t 0 $BCM_MULTIPASS_VM_IP:8443

    echo "Adding a lxd remote for $BCM_MULTIPASS_VM_NAME at $BCM_MULTIPASS_VM_IP:8443."
    lxc remote add $BCM_MULTIPASS_VM_NAME "$BCM_MULTIPASS_VM_IP:8443" --accept-certificate --password="$BCM_LXD_SECRET"
    lxc remote set-default $BCM_MULTIPASS_VM_NAME

    echo "Current lxd remote default is $BCM_MULTIPASS_VM_NAME."
  else
      echo "~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml exists. Continuing with existing file."
  fi
else
  if [[ ! -f ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml ]]; then
    #let's update our ENV to include the appropriate information from the
    #LXD cluster master. Grab the info then switch back to the new VM that we're creating.
    NEW_VM_NAME=$BCM_MULTIPASS_VM_NAME
    source ~/.bcm/endpoints/$BCM_LXD_CLUSTER_MASTER.env
    export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET
    source ~/.bcm/endpoints/$NEW_VM_NAME.env

    export BCM_LXD_CLUSTER_MASTER_IP=$(multipass list | grep "$BCM_LXD_CLUSTER_MASTER" | awk '{ print $3 }')
    export BCM_LXD_CLUSTER_CERTIFICATE=$(cat ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert | sed ':a;N;$!ba;s/\n/\n\n/g')

    touch /tmp/bcm/cert.txt
    echo "-----BEGIN CERTIFICATE-----" > /tmp/bcm/cert.txt
    echo "" >> /tmp/bcm/cert.txt
    grep -v '\-\-\-\-\-' ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert | sed ':a;N;$!ba;s/\n/\n\n/g' | sed 's/^/      /' >> /tmp/bcm/cert.txt
    echo "" >> /tmp/bcm/cert.txt
    echo "      -----END CERTIFICATE-----" >> /tmp/bcm/cert.txt
    echo "" >> /tmp/bcm/cert.txt

    export BCM_LXD_CLUSTER_CERTIFICATE=$(cat /tmp/bcm/cert.txt)
    mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
    envsubst < ./lxd_preseed/lxd_member_preseed.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/lxd_preseed.yml

    # upload the lxd preseed file to the multipass vm.
    multipass copy-files ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/lxd_preseed.yml $BCM_MULTIPASS_VM_NAME:/home/multipass/preseed.yml

    # now initialize the LXD daemon on the VM.
    multipass exec $BCM_MULTIPASS_VM_NAME -- sh -c "cat /home/multipass/preseed.yml | sudo lxd init --preseed"

  else
      echo "~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml exists. Continuing with existing file."
  fi
fi


# commit the files
cd ~/.bcm
git add *
git commit -am "Added ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env and ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME"
cd -
