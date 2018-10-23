#!/usr/bin/env bash


# removes an LXC container passed as $2 on the condition of $1

if [[ $1 = "true" ]]; then
    if [[ $(lxc list | grep $2) ]]; then
        # delete lxc container $2
        if [[ $(lxc info $2 | grep "Name: $2") ]]; then
            echo "Deleting lxc container '$2'."
            lxc delete --force $2
        fi
    fi
fi
