#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# here we will update our /etc/hosts with all the multipass vms.
# clearing all lines from /etc/hosts that contain "bcm-"
sudo sed -i '/multipass-/d' /etc/hosts

for LINE in $(multipass list --format csv | grep multipass-)
do
    MULTIPASS_VM_NAME="$(echo "$LINE" | awk -F "\"*,\"*" '{print $1}')"
    IPV4_ADDRESS="$(echo "$LINE" | awk -F "\"*,\"*" '{print $3}')"
    
    if [[ ! -z $IPV4_ADDRESS && ! -z $MULTIPASS_VM_NAME ]]; then
        echo "$IPV4_ADDRESS    $MULTIPASS_VM_NAME" | sudo tee -a /etc/hosts
    fi
done

sudo sed -i '/^$/d' /etc/hosts
