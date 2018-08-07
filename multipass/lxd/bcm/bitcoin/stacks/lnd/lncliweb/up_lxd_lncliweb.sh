# #!/bin/bash

# set -e

# # set the working directory to the location where the script is located
# cd "$(dirname "$0")"

# # determine if we need to build the image.
# if [[ $BCM_INSTALL_BITCOIN_LND_TESTNET_BUILD = "true" ]]; then
#     echo "Building and pushing $BCM_BITCOIN_LND_DOCKER_IMAGE to the private registry hosted on 'cachestack'."

#     lxc exec bitcoin -- mkdir -p /apps/lnd
#     lxc file push ./Dockerfile bitcoin/apps/lnd/Dockerfile
#     #lxc file push ./torrc bitcoin/apps/lnd/torrc
#     lxc file push ./docker-entrypoint.sh bitcoin/apps/lnd/docker-entrypoint.sh
#     #this step prepares custom images

#     lxc exec bitcoin -- docker build -t "$BCM_BITCOIN_LND_DOCKER_IMAGE" /apps/lnd
#     lxc exec bitcoin -- docker push "$BCM_BITCOIN_LND_DOCKER_IMAGE"

# fi

# echo "Deploying testnet lnd to lxd host 'bitcoin'."

# lxc exec manager1 -- mkdir -p /apps/lnd

# lxc file push ./lnd-mainnet.conf manager1/apps/lnd/lnd-mainnet.conf
# lxc file push ./lnd-testnet.conf manager1/apps/lnd/lnd-testnet.conf
# lxc file push ./lnd.yml manager1/apps/lnd/lnd.yml


# lxc exec manager1 -- env BCM_BITCOIN_LND_DOCKER_IMAGE=$BCM_BITCOIN_LND_DOCKER_IMAGE BCM_BITCOIN_BITCOIND_CHAIN="testnet" docker stack deploy -c /apps/lnd/lnd.yml lnd