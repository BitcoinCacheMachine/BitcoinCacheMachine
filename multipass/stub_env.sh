#!/bin/bash

TYPE=$1

# create the file
touch ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env

# generate an LXD secret for the new VM lxd endpoint.
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)


if [ $TYPE = "master" ]; then
    export BCM_CLUSTER_CERTIFICATE_LOCATION="~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd_cluster.cert"
    envsubst < ./env/multipass_master_defaults.env > ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
elif [ $TYPE = "member" ]; then
    envsubst < ./env/multipass_member_defaults.env > ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
else
    echo "Incorrect usage. Please specify whether $BCM_MULTIPASS_VM_NAME is an LXD cluster master or member."
fi

cd ~/.bcm
git add *
git commit -am "Added ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env"
cd -