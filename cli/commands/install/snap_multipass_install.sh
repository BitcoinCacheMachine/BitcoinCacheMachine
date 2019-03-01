#!/bin/bash

# Next make sure multipass is installed so we can run type-1 VMs
if ! snap list | grep -q multipass; then
    # if it doesn't, let's install
    echo "Performing a local LXD installation using multipass. Note this provides no fault tolerance."
    sudo snap install multipass --edge --classic
    sleep 10
fi
