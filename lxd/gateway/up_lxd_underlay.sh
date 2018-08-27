#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# before we even continue, ensure the appropriate ports actually exist.
if [[ $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE) ]]; then
    # now check inside
    if [[ $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE) ]]; then
        # deploy the actual deploy_lxd_gateway instance
        bash -c ./deploy_lxd_gateway.sh
    fi
fi
