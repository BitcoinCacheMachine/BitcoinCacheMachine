#!/bin/bash

# Next make sure multipass is installed so we can run type-1 VMs
if [[ -z $(snap list | grep multipass) ]]; then
    # if it doesn't, let's install
    sudo snap install multipass --beta --classic
fi