#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec cachestack -- docker stack ls | grep squid) ]]; then
    echo "Removing docker stack 'squid' from the swarm on 'cachestack'."
    lxc exec cachestack -- docker stack rm squid
    sleep 10
fi

lxc exec cachestack -- docker system prune -f
