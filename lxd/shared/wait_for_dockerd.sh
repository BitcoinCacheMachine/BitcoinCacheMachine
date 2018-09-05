#!/bin/bash

if [[ $(lxc list | grep $1) ]]; then
    while true; do
        if [[ $(lxc exec $1 -- systemctl is-active docker) == "active" ]]; then
            break
        fi

        sleep 1
    done
fi