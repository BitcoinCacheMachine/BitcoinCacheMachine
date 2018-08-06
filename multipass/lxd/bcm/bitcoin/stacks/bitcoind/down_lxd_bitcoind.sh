#!/bin/bash

# TODO create a way to dynamically determine if dependencies are running...

if [[ $(lxc exec manager1 -- docker stack ls | grep bitcoind) ]]; then
    echo "Removing docker stack 'bitcoind' from the swarm."
    lxc exec manager1 -- docker stack rm bitcoind
    sleep 10
fi

lxc exec bitcoin -- docker system prune -f

lxc exec bitcoin -- docker volume rm bitcoind_testnet_data