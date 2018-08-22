#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Create a docker host template if it doesn't exist already
if [[ -z $(lxc list | grep dockertemplate) ]]; then
    # Create a docker host template if it doesn't exist already
    if [[ -z $(lxc list | grep $BC_ZFS_POOL_NAME) ]]; then
        # create the host template if it doesn't exist already.
        bash -c ./host_template/up_lxd.sh
    fi

    # if the template doesn't exist, publish it create it.
    if [[ -z $(lxc image list | grep bctemplate) ]]; then
        echo "Publishing dockertemplate/dockerSnapshot snapshot as bctemplate lxd image."
        lxc publish $(lxc remote get-default):dockertemplate/dockerSnapshot --alias bctemplate
    fi
else
    echo "Skipping creation of the host template. Snapshot already exists."
fi