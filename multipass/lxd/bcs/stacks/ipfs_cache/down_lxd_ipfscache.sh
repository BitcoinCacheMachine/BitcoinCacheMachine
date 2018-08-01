#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec cachestack -- docker stack ls | grep ipfscache) ]]; then
    echo "Removing docker stack 'privateregistry' from the swarm on 'cachestack'."
    lxc exec cachestack -- docker stack rm ipfscache
    sleep 10
fi

lxc exec cachestack -- docker system prune -f
