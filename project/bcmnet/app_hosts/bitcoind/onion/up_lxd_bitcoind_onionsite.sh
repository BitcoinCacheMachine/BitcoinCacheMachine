#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

echo "Deploying bitcoind RPC onion site to lxd host 'bitcoin'."

lxc exec manager1 -- mkdir -p /apps/bitcoind/onion
lxc file push ./onionsite.yml manager1/apps/bitcoind/onion/onionsite.yml

# pass BCM_BITCOIN_BITCOIND_DOCKER_IMAGE to the stack.
lxc exec manager1 -- docker stack deploy -c /apps/bitcoind/onion/onionsite.yml bitcoindonionsite