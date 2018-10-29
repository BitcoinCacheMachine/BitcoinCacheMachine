#!/bin/bash


# let's install and configure docker-ce
if [[ -z $(snap list | grep docker) ]]; then
    if [[ -z $(groups | grep docker) ]]; then
        sudo addgroup --system docker
        sudo adduser $(whoami) docker
    fi
    
    sudo snap install docker --stable

    sudo snap disable docker
    sudo snap enable docker
fi
