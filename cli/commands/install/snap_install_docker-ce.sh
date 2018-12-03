#!/bin/bash


# let's install and configure docker-ce
if ! snap list | grep -q docker; then
    if ! groups | grep -q docker; then
        sudo addgroup --system docker
        sudo adduser "$(whoami)" docker
    fi
    
    sudo snap install docker --stable

    while true; do
        if systemctl is-active docker = "active"; then
            break
        fi

        sleep 1
        printf "."
    done
fi