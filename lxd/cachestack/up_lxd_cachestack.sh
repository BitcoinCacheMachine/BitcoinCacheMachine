#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Create the cachestack template lxc container only it doesnt exist yet.
if [[ -z $(lxc list | grep $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME) ]]; then
    bash -c ./create_lxc_cachestack_template.sh
fi



# bash -c ./create_cachestack_from_snapshot.sh