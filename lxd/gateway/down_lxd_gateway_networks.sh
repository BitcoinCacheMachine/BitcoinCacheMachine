#!/bin/bash

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