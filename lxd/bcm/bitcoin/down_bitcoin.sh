#!/bin/bash

set -eu

if [[ $(lxc exec manager1 -- docker stack ls | grep "lncli-web") ]]; then
    echo "Removing docker stack 'lncli-web' from the swarm."
    lxc exec manager1 -- docker stack rm lncli-web
fi

if [[ $(lxc exec manager1 -- docker stack ls | grep lnd) ]]; then
    echo "Removing docker stack 'lnd' from the swarm."
    lxc exec manager1 -- docker stack rm lnd
fi

if [[ $(lxc exec manager1 -- docker stack ls | grep lightningd) ]]; then
    echo "Removing docker stack 'lightningd' from the swarm."
    lxc exec manager1 -- docker stack rm lightningd
fi

if [[ $(lxc list | grep bitcoin) ]]; then
    if [[ $(lxc exec bitcoin -- docker info | grep "Swarm: active") ]]; then
        echo "Removing docker daemon in lxd host 'bitcoin' from the swarm."
        lxc exec bitcoin -- docker swarm leave
    fi
fi

if [[ $(lxc list | grep bitcoin) ]]; then
    echo "Destroying lxd container 'bitcoin'."
    lxc delete --force bitcoin
fi

if [[ $(lxc profile list | grep bitcoinprofile) ]]; then
    echo "Destroying lxd profile 'bitcoinprofile'."
   lxc profile delete bitcoinprofile
fi

if [[ $(lxc network list | grep lxdbrBitcoin) ]]; then
    echo "Destroying lxd network 'lxdbrBitcoin'."
   lxc network delete lxdbrBitcoin
fi

# if the user has instructed us to delete the dockervol backing.
if [[ $BCM_BITCOIN_DELETE_DOCKERVOL = "true" ]]; then
    if [[ $(lxc storage list | grep "bitcoin-dockervol") ]]; then
        echo "Destroying lxd storage pool 'bitcoin-dockervol'."
        lxc storage delete bitcoin-dockervol
    fi
fi