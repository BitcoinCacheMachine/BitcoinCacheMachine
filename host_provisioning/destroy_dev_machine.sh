#!/usr/bin/env bash

# this script removes all the stuff that up_dev_machine.sh put up there.

sudo rm -rf ~/.bcm/clusters
sudo rm -rf ~/.bcm/projects

bash -c "./trezor/destroy_trezor.sh -n $BCM_CURRENT_PROJECT_NAME"

SKIP_SOFTWARE_UNINSTALL=$1

if [[ $SKIP_SOFTWARE_UNINSTALL = "true" ]]; then
    sudo snap remove lxd

    sudo snap remove docker

    sudo snap remove multipass
else
    echo "Skipping software uninstall."
fi

if [[ ! -z $(zpool list | grep "bcm_data") ]]; then
    sudo zpool destroy bcm_data
fi
