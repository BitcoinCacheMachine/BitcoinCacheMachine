#!/bin/bash

if [[ $(lxc exec underlay -- docker stack ls | grep squid) ]]; then
    echo "Removing docker stack 'squid' from the swarm on 'squid'."
    lxc exec underlay -- docker stack rm squid
    sleep 10
fi

lxc exec underlay -- docker system prune -f
