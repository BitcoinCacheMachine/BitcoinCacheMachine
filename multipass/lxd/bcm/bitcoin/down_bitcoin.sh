#!/bin/bash

set -e

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
