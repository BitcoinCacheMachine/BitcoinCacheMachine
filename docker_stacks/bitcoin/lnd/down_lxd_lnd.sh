#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec manager1 -- docker stack ls | grep lnd) ]]; then
    echo "Removing docker stack 'lnd' from the swarm."
    lxc exec manager1 -- docker stack rm lnd
    sleep 5
fi

lxc exec bitcoin -- docker system prune -f

sleep 15

#lxc exec bitcoin -- docker volume rm lnd_lnd-data lnd_lnd-log-data lnd_lnd-certificate-data lnd_lnd-macaroon-data