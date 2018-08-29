#!/bin/bash

# if the user has instructed us to delete the dockervol backing.
if [[ $1 = "true" ]]; then
    # delete lxd storage gateway
    if [[ $(lxc network list | grep $2) ]]; then
        lxc network delete $2
    fi
fi
