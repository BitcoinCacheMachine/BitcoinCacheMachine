#!/bin/bash

if [[ $1 = "true" ]]; then

    # create the $2 profile if it doesn't exist.
    if [[ -z $(lxc profile list | grep $2) ]]; then
        lxc profile create $2
    fi

    echo "Applying $3 to lxc profile '$2'."
    cat $3 | lxc profile edit $2
fi
