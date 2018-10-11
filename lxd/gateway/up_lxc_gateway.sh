#!/bin/bash


set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# Create the gateway template lxc container only it doesnt exist yet.
if [[ -z $(lxc list | grep $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME) ]]; then
    bash -c ./create_lxc_gateway_template.sh
fi

#now create the actual runtime gateway from the snapshot.
bash -c ./create_lxc_gateway_from_snapshot.sh