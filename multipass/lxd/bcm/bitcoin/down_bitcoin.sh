#!/bin/bash

set -e

# load the environment variables for the current LXD remote.
source ~/.bcm/bcm_env.sh

if [[ $(lxc exec manager1 -- docker stack ls | grep bitcoind) ]]; then
    echo "Removing docker stack 'bitcoind' from the swarm."
    lxc exec manager1 -- docker stack rm bitcoind
    sleep 10
else
    echo "Didn't find the bitcoind docker stack running. SKipping 'docker stack rm bitciond'."
fi


if [[ $(lxc list | grep bitcoin) ]]; then
    echo "Destroying lxd container 'bitcoin'."
    lxc delete --force bitcoin
else
    echo "LXC container 'bitcoin' not found. Skipping."
fi

if [[ $(lxc profile list | grep bitcoinprofile) ]]; then
    echo "Destroying lxd profile 'bitcoinprofile'."
   lxc profile delete bitcoinprofile
else
    echo "LXC profile 'bitcoinprofile' not found. Skipping."
fi


if [[ $(lxc network list | grep lxdbrBitcoin) ]]; then
    echo "Destroying lxd network 'lxdbrBitcoin'."
   lxc network delete lxdbrBitcoin
else
    echo "LXC network 'lxdbrBitcoin' not found. Skipping."
fi

if [[ $(lxc storage list | grep "bitcoin-dockervol") ]]; then
    echo "Destroying lxd storage pool 'bitcoin-dockervol'."
   lxc storage delete bitcoin-dockervol
else
    echo "LXC storage pool 'bitcoin-dockervol' not found. Skipping."
fi
