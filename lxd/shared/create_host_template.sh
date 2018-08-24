#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Create a docker host template if it doesn't exist already
if [[ -z $(lxc list | grep dockertemplate) ]]; then
    # Create a docker host template if it doesn't exist already
    if [[ -z $(lxc list | grep "bcm_data") ]]; then
        # create the host template if it doesn't exist already.
        bash -c ../host_template/up_lxd_host_template.sh
    fi

else
    echo "Skipping creation of the host template. Snapshot already exists."
fi