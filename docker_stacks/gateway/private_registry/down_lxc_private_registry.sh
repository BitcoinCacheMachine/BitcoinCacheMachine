#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec cachestack -- docker stack ls | grep privateregistry) ]]; then
    echo "Removing docker stack 'privateregistry' from the swarm on 'cachestack'."
    lxc exec bcm-cachestack -- docker stack rm privateregistry
    sleep 10
fi

lxc exec bcm-cachestack -- docker system prune -f
