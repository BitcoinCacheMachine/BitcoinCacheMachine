# #!/bin/bash

# set -e

# # set the working directory to the location where the script is located
# cd "$(dirname "$0")"

# if [[ $BCM_INSTALL_BITCOIN_BITCOIND_TESTNET_BUILD = "true" ]]; then
#     echo "Building and pushing $BCM_BITCOIN_BITCOIND_DOCKER_IMAGE to the private registry hosted on 'cachestack'."

#     lxc exec bitcoin -- mkdir -p /apps/bitcoind
#     lxc file push ./Dockerfile bitcoin/apps/bitcoind/Dockerfile
#     lxc file push ./docker-entrypoint.sh bitcoin/apps/bitcoind/docker-entrypoint.sh
#     #this step prepares custom images

#     lxc exec bitcoin -- docker build -t "$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE" /apps/bitcoind
#     lxc exec bitcoin -- docker push "$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE"
# else
#     BCM_BITCOIN_BITCOIND_DOCKER_IMAGE="<FIXME>/bitcoind:16.1"
# fi

# lxc exec bitcoin -- docker volume create bitcoind_testnet_data

# if [[ $BCM_INSTALL_BITCOIN_BITCOIND_TESTNET_RSYNC_BOOTSTRAP = "true" ]]; then
#     echo "Bootstrapping bitcoind testnet data directory using rsync from files hosted on $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE."
#     lxc exec bitcoin -- docker pull cachestack.lxd/rsyncd:latest

#     # next, run the container with the rsync client on it and do a remote-to-local rsync pull
#     # from the LXD host running the cachestack TO the local BCM instance.
#     RSYNC_IP_ADDRESS=$(lxc list $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE:cachestack --columns 4 | grep eth3 | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

#     lxc file push $BCM_RUNTIME_DIR/endpoints/"$BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE"/.ssh/cachestack-rsync-key bitcoin/apps/bitcoind/id_rsa_rsyncd_cachestack

#     echo "Pulling via rsync from $RSYNC_IP_ADDRESS:bitcoind_testnet_data/ to docker volume bitcoind_testnet_data."
#     lxc exec bitcoin -- docker run -it --rm -v /apps/bitcoind/id_rsa_rsyncd_cachestack:/root/.ssh/rsync_rsa_key -v bitcoind_testnet_data:/bitcoindata cachestack.lxd/rsyncd:latest rsync -av -e "ssh -i /root/.ssh/rsync_rsa_key -p 2222 -l rsync -o StrictHostKeyChecking=no" "$RSYNC_IP_ADDRESS":bitcoind_testnet_data/ /bitcoindata/
# fi

# echo "Deploying bitcoind services to lxd host 'bitcoin'."

# lxc exec manager1 -- mkdir -p /apps/bitcoind

# lxc file push ./bitcoind-mainnet.conf manager1/apps/bitcoind/bitcoind-mainnet.conf
# lxc file push ./bitcoind-testnet.conf manager1/apps/bitcoind/bitcoind-testnet.conf
# lxc file push ./bitcoind.yml manager1/apps/bitcoind/bitcoind.yml
# lxc file push ./torrc manager1/apps/bitcoind/torrc

# # pass BCM_BITCOIN_BITCOIND_DOCKER_IMAGE to the stack.
# lxc exec manager1 -- env BCM_BITCOIN_BITCOIND_DOCKER_IMAGE=$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE BCM_BITCOIN_BITCOIND_CHAIN="testnet" docker stack deploy -c /apps/bitcoind/bitcoind.yml bitcoind
