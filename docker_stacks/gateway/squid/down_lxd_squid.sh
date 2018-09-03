#!/bin/bash

if [[ $(lxc exec bcm-gateway -- docker stack ls | grep squid) ]]; then
    echo "Removing docker stack 'squid' from the swarm on 'squid'."
    lxc exec bcm-gateway -- docker stack rm squid
    sleep 10
fi

lxc exec bcm-gateway -- docker system prune -f