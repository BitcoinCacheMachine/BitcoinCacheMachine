#!/bin/bash

# if the user has instructed us to delete the dockervol backing.
if [[ $BCM_GATEWAY_DELETE_DOCKERVOL = "true" ]]; then
    # delete lxd storage gateway-dockervol 
    if [[ $(lxc storage list | grep "gateway-dockervol") ]]; then
        echo "Deleting lxd storage pool 'gateway-dockervol'."
        lxc storage delete gateway-dockervol
    fi
fi
