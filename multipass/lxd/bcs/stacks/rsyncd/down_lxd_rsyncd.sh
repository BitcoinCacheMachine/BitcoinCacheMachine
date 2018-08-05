#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec cachestack -- docker stack ls | grep rsyncd) ]]; then
    echo "Removing docker stack 'rsyncd' from the swarm on 'cachestack'."
    lxc exec cachestack -- docker stack rm rsyncd
fi

sleep 5

lxc exec cachestack -- docker system prune -f


if [[ $BCS_DELETE_RSYNC_DATA_DOCKER_VOL = "true" ]]; then
    lxc exec cachestack -- docker volume rm rsyncd_rsyncd-data
fi