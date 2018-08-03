#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

if [[ $BCM_INSTALL_BITCOIN_BITCOIND_TESTNET_BUILD = "true" ]]; then
    echo "Building and pushing $BCM_BITCOIN_BITCOIND_DOCKER_IMAGE to the private registry hosted on 'cachestack'."

    lxc exec bitcoin -- mkdir -p /apps/bitcoind
    lxc file push ./Dockerfile bitcoin/apps/bitcoind/Dockerfile
    lxc file push ./docker-entrypoint.sh bitcoin/apps/bitcoind/docker-entrypoint.sh
    #this step prepares custom images

    lxc exec bitcoin -- docker build -t "$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE" /apps/bitcoind
    lxc exec bitcoin -- docker push "$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE"
else
    BCM_BITCOIN_BITCOIND_DOCKER_IMAGE="farscapian/bitcoind:16.1"
fi

echo "Deploying bitcoind services to lxd host 'bitcoin'."

lxc exec manager1 -- mkdir -p /apps/bitcoind

lxc file push ./bitcoind-mainnet.conf manager1/apps/bitcoind/bitcoind-mainnet.conf
lxc file push ./bitcoind-testnet.conf manager1/apps/bitcoind/bitcoind-testnet.conf
lxc file push ./bitcoind.yml manager1/apps/bitcoind/bitcoind.yml
lxc file push ./torrc manager1/apps/bitcoind/torrc

# pass BCM_BITCOIN_BITCOIND_DOCKER_IMAGE to the stack.
lxc exec manager1 -- env BCM_BITCOIN_BITCOIND_DOCKER_IMAGE=$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE BCM_BITCOIN_BITCOIND_CHAIN="testnet" docker stack deploy -c /apps/bitcoind/bitcoind.yml bitcoind