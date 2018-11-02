#!/bin/bash


# create a local cluster of LXD hosts based on 
# multipass VMs with local network for LXD API endpoint
bcm cluster create -c=dev -t=multipass -l=3 -x=net