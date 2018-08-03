#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec manager1 -- docker stack ls | grep bitcoindonionsite) ]]; then
    echo "Removing docker stack 'bitcoindonionsite' from the swarm."
    lxc exec manager1 -- docker stack rm bitcoindonionsite
    sleep 10
fi

lxc exec bitcoin -- docker system prune -f
