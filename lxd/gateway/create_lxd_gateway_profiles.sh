#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create the gatewayprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep gatewayprofile) ]]; then
    lxc profile create gatewayprofile
fi

echo "Applying gateway_lxd_profile.yml to lxd profile 'gatewayprofile'."
cat gateway_lxd_profile.yml | lxc profile edit gatewayprofile
