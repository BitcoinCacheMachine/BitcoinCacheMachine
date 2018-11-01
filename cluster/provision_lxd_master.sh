#!/bin/bash

set -eu

VM_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME
LXD_DIR=$VM_DIR/lxd

mkdir -p $LXD_DIR

 # substitute the variables in lxd_master_preseed.yml
envsubst < ./lxd_preseed/lxd_master_preseed.yml > $LXD_DIR/preseed.yml

# upload the lxd preseed file to the multipass vm.
multipass copy-files $LXD_DIR/preseed.yml $BCM_CLUSTER_ENDPOINT_NAME:/home/multipass/preseed.yml

# now initialize the LXD daemon on the VM.
multipass exec $BCM_CLUSTER_ENDPOINT_NAME -- sh -c "cat /home/multipass/preseed.yml | sudo lxd init --preseed"

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_pressed files.
if [[ ! -f $VM_DIR/lxd/lxd.cert ]]; then
  # lets' get the resulting cluster certificate fingerprint and store it in the .env for the cluster master.
  mkdir -p $LXD_DIR
  multipass exec $BCM_CLUSTER_ENDPOINT_NAME -- cat /var/snap/lxd/common/lxd/server.crt >> $LXD_DIR/lxd.cert
fi

echo "Waiting for the remote lxd daemon to become available."
wait-for-it -t 0 $BCM_ENDPOINT_VM_IP:8443

echo "Adding a lxd remote for $BCM_CLUSTER_ENDPOINT_NAME at $BCM_ENDPOINT_VM_IP:8443."
lxc remote add $BCM_CLUSTER_ENDPOINT_NAME "$BCM_ENDPOINT_VM_IP:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote set-default $BCM_CLUSTER_ENDPOINT_NAME

echo "Current lxd remote default is $BCM_CLUSTER_ENDPOINT_NAME."

bash -c "commit_bcm.sh 'Added master LXD preseed files at $LXD_DIR'"