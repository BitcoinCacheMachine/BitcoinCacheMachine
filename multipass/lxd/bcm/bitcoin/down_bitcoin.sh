#!/bin/bash

set -e

# load the environment variables for the current LXD remote.
source ~/.bcm/bcm_env.sh

echo "1"
if [[ $(lxc exec manager1 -- docker stack ls | grep "lncli-web") ]]; then
    echo "Removing docker stack 'lncli-web' from the swarm."
    lxc exec manager1 -- docker stack rm lncli-web
fi

echo "2"
if [[ $(lxc exec manager1 -- docker stack ls | grep lnd) ]]; then
    echo "Removing docker stack 'lnd' from the swarm."
    lxc exec manager1 -- docker stack rm lnd
fi

echo "3"
if [[ $(lxc exec manager1 -- docker stack ls | grep lightningd) ]]; then
    echo "Removing docker stack 'lightningd' from the swarm."
    lxc exec manager1 -- docker stack rm lightningd
fi

echo "5"
if [[ $(lxc list | grep bitcoin) ]]; then
    if [[ $(lxc exec bitcoin -- docker info | grep "Swarm: active") ]]; then
        echo "Removing docker daemon in lxd host 'bitcoin' from the swarm."
        lxc exec bitcoin -- docker swarm leave
    fi
fi

echo "6"
if [[ $(lxc list | grep bitcoin) ]]; then
    echo "Destroying lxd container 'bitcoin'."
    lxc delete --force bitcoin
fi

echo "7"
if [[ $(lxc profile list | grep bitcoinprofile) ]]; then
    echo "Destroying lxd profile 'bitcoinprofile'."
   lxc profile delete bitcoinprofile
fi

echo "8"
if [[ $(lxc network list | grep lxdbrBitcoin) ]]; then
    echo "Destroying lxd network 'lxdbrBitcoin'."
   lxc network delete lxdbrBitcoin
fi

echo "9"
# if the user has instructed us to delete the dockervol backing.
if [[ $BCM_BITCOIN_DELETE_DOCKERVOL = "true" ]]; then
    if [[ $(lxc storage list | grep "bitcoin-dockervol") ]]; then
        echo "Destroying lxd storage pool 'bitcoin-dockervol'."
        lxc storage delete bitcoin-dockervol
    fi
fi