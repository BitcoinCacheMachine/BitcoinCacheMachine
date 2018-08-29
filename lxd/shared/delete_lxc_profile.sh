#!/bin/bash

# if the user has instructed us to delete the dockervol backing.
if [[ $1 = "true" ]]; then
    # delete lxd storage gateway
    if [[ $(lxc profile list | grep "$2") ]]; then
        echo "Deleting lxd profile '$2'."
        lxc profile delete "$2"
    fi
fi