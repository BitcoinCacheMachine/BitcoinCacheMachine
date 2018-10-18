#!/bin/bash

set -eu

VM_DIR=$ENDPOINTS_DIR/$BCM_MULTIPASS_VM_NAME

mkdir -p $VM_DIR/lxd

 # substitute the variables in lxd_master_preseed.yml
envsubst < ./lxd_preseed/lxd_master_preseed.yml > $VM_DIR/lxd/preseed.yml

# upload the lxd preseed file to the multipass vm.
multipass copy-files $VM_DIR/lxd/preseed.yml $BCM_MULTIPASS_VM_NAME:/home/multipass/preseed.yml

# now initialize the LXD daemon on the VM.
multipass exec $BCM_MULTIPASS_VM_NAME -- sh -c "cat /home/multipass/preseed.yml | sudo lxd init --preseed"

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_pressed files.
if [[ ! -f $VM_DIR/lxd/lxd.cert ]]; then
  # lets' get the resulting cluster certificate fingerprint and store it in the .env for the cluster master.
  mkdir -p $VM_DIR/lxd
  multipass exec $BCM_MULTIPASS_VM_NAME -- cat /var/snap/lxd/common/lxd/server.crt >> $VM_DIR/lxd/lxd.cert
fi

echo "Waiting for the remote lxd daemon to become available."
wait-for-it -t 0 $BCM_MULTIPASS_VM_IP:8443

echo "Adding a lxd remote for $BCM_MULTIPASS_VM_NAME at $BCM_MULTIPASS_VM_IP:8443."
lxc remote add $BCM_MULTIPASS_VM_NAME "$BCM_MULTIPASS_VM_IP:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote set-default $BCM_MULTIPASS_VM_NAME

echo "Current lxd remote default is $BCM_MULTIPASS_VM_NAME."

bash -c "$BCM_LOCAL_GIT_REPO/resources/commit_bcm.sh"