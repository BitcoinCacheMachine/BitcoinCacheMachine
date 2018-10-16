#!/bin/bash

set -eu

for vm in "bcm-03" "bcm-02" "bcm-01" "bcm-00"
do
    export BCM_MULTIPASS_VM_NAME=$vm
    bash -c "./destroy_multipass.sh $BCM_MULTIPASS_VM_NAME"
done
