#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# delete lxd container underlay
if [[ $(lxc info underlay | grep "Status: Running") ]]; then
    echo "Deleting lxd container 'underlay'."
    lxc delete --force underlay
fi


if [[ $BCM_UNDERLAY_TEMPLATE_DELETE = "true" ]]; then
    # delete lxd container underlay-template
    if [[ $(lxc info underlay-template | grep "Name: underlay-template") ]]; then
        echo "Deleting lxd container 'underlay-template'."
        lxc delete --force underlay-template
    fi
fi


# delete lxd container underlay
if [[ $(lxc profile list | grep underlayprofile) ]]; then
    echo "Deleting lxd profile 'underlayprofile'."
    lxc profile delete underlayprofile >/dev/null
fi


# delete lxd network lxdbrUnderlay 
if [[ $(lxc network list | grep lxdbrUnderlay) ]]; then
    echo "Deleting lxd network 'lxdbrUnderlay'."
    lxc network delete lxdbrUnderlay
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
if [[ $BCM_UNDERLAY_DELETE_DOCKERVOL = "true" ]]; then
    # delete lxd storage underlay-dockervol 
    if [[ $(lxc storage list | grep "underlay-dockervol") ]]; then
        echo "Deleting lxd storage pool 'underlay-dockervol'."
        lxc storage delete underlay-dockervol
    fi
fi


