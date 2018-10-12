#!/bin/bash

# brings up LXD cluster of 3 multipass vms.


export BCM_MULTIPASS_VM_NAME="bcm-01"
export BCM_MULTIPASS_CLUSTER_MASTER=$BCM_MULTIPASS_VM_NAME
bash -c ./stub_env.sh >> /dev/null
source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
./up_multipass.sh true


export BCM_MULTIPASS_VM_NAME="bcm-02"
bash -c ./stub_env.sh >> /dev/null
source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
./up_multipass.sh false $BCM_MULTIPASS_CLUSTER_MASTER


# export BCM_MULTIPASS_VM_NAME="bcm-03"
# bash -c ./stub_env.sh >> /dev/null
# source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
# ./up_multipass.sh false $BCM_MULTIPASS_CLUSTER_MASTER