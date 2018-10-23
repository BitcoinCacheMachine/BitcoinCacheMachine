#!/usr/bin/env bash

# this script removes all the stuff that up_dev_machine.sh put up there.

rm -Rf ~/.bcm/clusters

sudo snap remove lxd

sudo snap remove docker

sudo snap remove multipass

if [[ ! -z $(zpool list | grep "bcm_data") ]]; then
    sudo zpool destroy bcm_data
fi