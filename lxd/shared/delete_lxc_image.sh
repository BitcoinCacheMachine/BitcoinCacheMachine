#!/bin/bash

# deleting an image from the current lxd context
if [[ $1 = "true" ]]; then
    # delete lxc image
    if [[ $(lxc image list | grep $2) ]]; then
        echo "Deleting lxc image '$2'."
        lxc image delete $2
    fi
fi
