#!/bin/bash

## TODO check parameters.

# Delete the dockervol if instructed
if [[ $1 = "true" ]]; then
    # delete lxd storage gateway 
    if [[ $(lxc storage list | grep $2) ]]; then
        echo "Deleting lxd storage pool '$2'."
        lxc storage delete $2
    fi
fi
