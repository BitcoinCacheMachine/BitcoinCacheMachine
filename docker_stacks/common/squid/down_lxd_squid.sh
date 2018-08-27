#!/bin/bash

if [[ $(lxc exec gateway -- docker stack ls | grep squid) ]]; then
    echo "Removing docker stack 'squid' from the swarm on 'squid'."
    lxc exec gateway -- docker stack rm squid
    sleep 10
fi

lxc exec gateway -- docker system prune -f
