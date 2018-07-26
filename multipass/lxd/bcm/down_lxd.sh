#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# delete lxd container cachestack
if [[ $(lxc list | grep elastic) ]]; then
    echo "Destrying elastic stuff"
    ./elastic/down_elastic.sh >/dev/null
else
    echo "Skipping deletion of lxd container 'elastic'."
fi


# delete lxd container bitcoin
if [[ $(lxc list | grep bitcoin) ]]; then
    echo "Destroying lxd host bitcoin"
    ./bitcoin/down_bitcoin.sh >/dev/null
else
    echo "Skipping deletion of lxd container 'bitcoin'."
fi


# delete lxd container managers
if [[ $(lxc list | grep manager) ]]; then
    echo "Destroying managers"
    ./managers/down_managers.sh >/dev/null
else
    echo "Skipping deletion of lxd container 'manager*'."
fi


# delete lxd container managers
if [[ $(lxc list | grep proxyhost) ]]; then
    echo "Destroying proxyhost"
    ./proxyhost/down_proxyhost.sh >/dev/null
else
    echo "Skipping deletion of lxd container 'proxyhost*'."
fi

