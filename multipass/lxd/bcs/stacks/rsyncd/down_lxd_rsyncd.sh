#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec cachestack -- docker stack ls | grep rsyncd) ]]; then
    echo "Removing docker stack 'rsyncd' from the swarm on 'cachestack'."
    lxc exec cachestack -- docker stack rm rsyncd
    sleep 10
fi

lxc exec cachestack -- docker system prune -f
