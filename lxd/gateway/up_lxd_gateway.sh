#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"


# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit 1
fi

bash -c ./create_lxd_gateway-template.sh

# before we even continue, ensure the appropriate ports actually exist.
if [[ $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE) ]]; then
    # now check inside
    if [[ $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE) ]]; then
        # deploy the actual deploy_lxd_gateway instance
        bash -c ./deploy_lxd_gateway.sh
    else
        echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE' doesn't exist on LXD host '$(lxc remote get-default)'. Please update BCM environment variable BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE."
    fi
else
    echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE' doesn't exist on LXD host '$(lxc remote get-default)'. Please update BCM environment variable BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE."
fi
