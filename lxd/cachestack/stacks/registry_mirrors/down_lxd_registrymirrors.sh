#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec cachestack -- docker stack ls | grep registrymirrors) ]]; then
    echo "Removing docker stack 'registry_mirrors' from the swarm on 'cachestack'."
    lxc exec cachestack -- docker stack rm registrymirrors
    sleep 10
fi

lxc exec cachestack -- docker system prune -f

lxc exec cachestack -- docker volume rm registrymirrors_registrymirrorimage-data