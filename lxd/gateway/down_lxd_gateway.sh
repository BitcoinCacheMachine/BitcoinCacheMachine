#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# delete lxd container gateway
if [[ $(lxc list | grep gateway) ]]; then
    if [[ $(lxc info gateway | grep "Name: gateway") ]]; then
        echo "Deleting lxd container 'gateway'."
        lxc delete --force gateway
    fi
fi


if [[ $BCM_GATEWAY_TEMPLATE_DELETE = "true" ]]; then
    if [[ $(lxc list | grep "gateway-template") ]]; then
        # delete lxd container gateway-template
        if [[ $(lxc info gateway-template | grep "Name: gateway-template") ]]; then
            echo "Deleting lxd container 'gateway-template'."
            lxc delete --force gateway-template
        fi
    fi
fi


# delete lxd container gateway
if [[ $(lxc profile list | grep gatewayprofile) ]]; then
    echo "Deleting lxd profile 'gatewayprofile'."
    lxc profile delete gatewayprofile >/dev/null
fi


# delete lxd network lxdbrGateway
if [[ $(lxc network list | grep lxdbrGateway) ]]; then
    echo "Deleting lxd network 'lxdbrGateway'."
    lxc network delete lxdbrGateway
fi


# delete lxd network lxdBCMCSMGRNET 
if [[ $(lxc network list | grep lxdBCMCSMGRNET) ]]; then
    echo "Deleting lxd network 'lxdBCMCSMGRNET'."
    lxc network delete lxdBCMCSMGRNET
fi

# delete lxd network lxdBrNowhere 
if [[ $(lxc network list | grep lxdBrNowhere) ]]; then
    echo "Deleting lxd network 'lxdBrNowhere'."
    lxc network delete lxdBrNowhere
fi


# if the user has instructed us to delete the dockervol backing.
if [[ $BCM_GATEWAY_DELETE_DOCKERVOL = "true" ]]; then
    # delete lxd storage gateway-dockervol 
    if [[ $(lxc storage list | grep "gateway-dockervol") ]]; then
        echo "Deleting lxd storage pool 'gateway-dockervol'."
        lxc storage delete gateway-dockervol
    fi
fi
