#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec manager1 -- docker stack ls | grep lightningd) ]]; then
    echo "Removing docker stack 'lightningd' from the swarm."
    lxc exec manager1 -- docker stack rm lightningd
    sleep 5
fi

lxc exec bitcoin -- docker system prune -f
