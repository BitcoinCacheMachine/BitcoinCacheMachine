#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# determine if we need to build the image.
if [[ $BCM_INSTALL_BITCOIN_LIGHTNING_CHARGE_BUILD = "true" ]]; then
    echo "Building and pushing $BCM_INSTALL_BITCOIN_LIGHTNING_CHARGE_DOCKER_IMAGE."

    lxc exec bitcoin -- mkdir -p /apps/lightningd/lightning-charge
    lxc file push ./Dockerfile bitcoin/apps/lightningd/lightning-charge/Dockerfile
    lxc file push ./package.json bitcoin/apps/lightningd/lightning-charge/package.json
    lxc file push ./docker-entrypoint.sh bitcoin/apps/lightningd/lightning-charge/docker-entrypoint.sh
    #this step prepares custom images

    lxc exec bitcoin -- docker build -t "$BCM_INSTALL_BITCOIN_LIGHTNING_CHARGE_DOCKER_IMAGE" /apps/lightningd/lightning-charge/
    lxc exec bitcoin -- docker push "$BCM_INSTALL_BITCOIN_LIGHTNING_CHARGE_DOCKER_IMAGE"

fi

# echo "Deploying testnet lightning-charge to lxd host 'bitcoin'."

# lxc exec manager1 -- mkdir -p /apps/lnd/lightning-charge
# lxc file push ./lightning-charge.yml manager1/apps/lnd/lightning-charge/lightning-charge.yml

# lxc exec manager1 -- env BCM_BITCOIN_LIGHTNINGD_DOCKER_IMAGE=$BCM_BITCOIN_LIGHTNINGD_DOCKER_IMAGE BCM_BITCOIN_BITCOIND_CHAIN="testnet" docker stack deploy -c /apps/lightningd/lightningd.yml lightningd