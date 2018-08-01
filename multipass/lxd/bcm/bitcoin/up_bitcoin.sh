#!/bin/bash

# quit script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# load the environment variables for the current LXD remote.
source ~/.bcm/bcm_env.sh

# create the lxdbrBitcoin network, which is used for all outbound access
# by services residing on the lxd host `bitcoin`
if [[ -z $(lxc network list | grep lxdbrBitcoin) ]]; then
    # a bridged network created for all services residing on the LXC host 'bitcoin'
    lxc network create lxdbrBitcoin ipv4.nat=true
else
  echo "LXD network lxdbrBitcoin already exists, skipping initial creation."
fi



# create the profile 'bitcoinprofile'
if [[ -z $(lxc profile list | grep bitcoinprofile) ]]; then
    # create the bitcoin profile
    lxc profile create bitcoinprofile
else
  echo "LXD profile bitcoinprofile already exists, skipping initial creation."
fi

echo "Applying ./bitcoin_lxd_profile.yml to lxd profile 'bitcoinprofile'."
cat ./bitcoin_lxd_profile.yml | lxc profile edit bitcoinprofile


# create the profile 'bitcoinprofile'
if [[ -z $(lxc profile list | grep bitcoinprofile) ]]; then
    # create the bitcoin profile
    lxc profile create bitcoinprofile
else
  echo "LXD profile bitcoinprofile already exists, skipping initial creation."
fi


## Create the manager1 host from the lxd image template.
lxc init bctemplate bitcoin -p docker -p dockertemplate_profile -s $BC_ZFS_POOL_NAME

echo "Applying the lxd profiles 'bitcoinprofile' and 'docker' to the lxd host 'bitcoin'."
lxc profile apply bitcoin docker,bitcoinprofile



# create the bitcoin-dockervol storage pool.
## TODO refactor this method out for re-use (any up/down 'host-dockervol')
if [[ -z $(lxc storage list | grep "bitcoin-dockervol") ]]; then
    # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
    lxc storage create bitcoin-dockervol dir
    lxc config device add bitcoin dockerdisk disk source=$(lxc storage show bitcoin-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
else
    echo "bitcoin-dockervol lxd storage pool already exists; attaching it to LXD container 'bitcoin'."
    lxc config device add bitcoin dockerdisk disk source=$(lxc storage show bitcoin-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
fi

if [[ $BCM_DISABLE_DOCKER_GELF = "true" ]]; then
  # push docker.json for registry mirror settings
  lxc file push ./dockerd_nogelf.json bitcoin/etc/docker/daemon.json
else
  # push docker.json for registry mirror settings
  lxc file push ./dockerd.json bitcoin/etc/docker/daemon.json
fi


lxc start bitcoin

sleep 10

# update routing table in bitcoin lxd host to prefer eth0 for outbound access.
lxc exec bitcoin -- ifmetric eth0 0




WORKER_TOKEN=$(lxc exec manager1 -- docker swarm join-token worker | grep token | awk '{ print $5 }')

lxc exec bitcoin -- docker swarm join 10.0.0.11 --token $WORKER_TOKEN

############################
############################

# install bitcoid if specified
if [[ $BCM_INSTALL_BITCOIN_BITCOIND_TESTNET = "true" ]]; then

  # determine if we need to build the image.
  if [[ $BCM_INSTALL_BITCOIN_BITCOIND_BUILD = "true" ]]; then
    echo "Building and pushing bitcoind."
    lxc file push ./stacks/bitcoind/Dockerfile manager1/apps/bitcoind/Dockerfile
    lxc file push ./stacks/bitcoind/docker-entrypoint.sh manager1/apps/bitcoind/docker-entrypoint.sh
    #this step prepares custom images

    lxc exec manager1 -- docker build -t cachestack.lan/lnd:latest /apps/bitcoind
    lxc exec manager1 -- docker push cachestack.lan/lnd:latest
  fi


  echo "Deploying bitcoind services to lxd host 'bitcoin'."
  lxc exec manager1 -- mkdir -p /apps/bitcoind

  lxc file push ./stacks/bitcoind/bitcoind-mainnet.conf manager1/apps/bitcoind/bitcoind-mainnet.conf
  lxc file push ./stacks/bitcoind/bitcoind-testnet.conf manager1/apps/bitcoind/bitcoind-testnet.conf
  lxc file push ./stacks/bitcoind/bitcoind.yml manager1/apps/bitcoind/bitcoind.yml
  lxc file push ./stacks/bitcoind/torrc manager1/apps/bitcoind/torrc
  
  # pass BCM_BITCOIN_BITCOIND_DOCKER_IMAGE to the stack.
  lxc exec manager1 -- env BCM_BITCOIN_BITCOIND_DOCKER_IMAGE=$BCM_BITCOIN_BITCOIND_DOCKER_IMAGE \
                            docker stack deploy -c /apps/bitcoind/bitcoind.yml bitcoind
fi



# install lightningd (c-lightning) if specified (testnet)
if [[ $BCM_INSTALL_BITCOIN_LIGHTNINGD_TESTNET = "true" ]]; then
  echo "Deploying testnet lightningd (c-lightning) to lxd host 'bitcoin'."
  lxc exec manager1 -- mkdir -p /apps/lightningd

  lxc file push ./stacks/lightningd/lightningd-mainnet.conf manager1/apps/lightningd/lightningd-mainnet.conf
  lxc file push ./stacks/lightningd/lightningd-testnet.conf manager1/apps/lightningd/lightningd-testnet.conf
  lxc file push ./stacks/lightningd/lightningd.yml manager1/apps/lightningd/lightningd.yml
  lxc file push ./stacks/lightningd/torrc manager1/apps/lightningd/torrc

  lxc exec manager1 -- docker stack deploy -c /apps/lightningd/lightningd.yml lightningd
fi


# # install lnd if specified
# if [[ $BCM_INSTALL_BITCOIN_LND_TESTNET = "true" ]]; then
#   echo "Deploying testnet lightning network daemon (lnd) to lxd host 'bitcoin'."
#   lxc exec manager1 -- mkdir -p /apps/lnd

#   lxc file push ./stacks/lnd/lnd-mainnet.conf manager1/apps/lnd/lnd-mainnet.conf
#   lxc file push ./stacks/lnd/lnd-testnet.conf manager1/apps/lnd/lnd-testnet.conf
#   lxc file push ./stacks/lnd/lnd.yml manager1/apps/lnd/lnd.yml

#   lxc exec manager1 -- docker stack deploy -c /apps/lnd/lnd.yml lnd
# fi

# if [[ $BCM_INSTALL_BITCOIN_LND_LNCLIWEB = "true" ]]; then
#   echo "Deploying lncli-web web interface (for lnd) to lxd host 'bitcoin'."
#   lxc exec manager1 -- mkdir -p /apps/lncliweb

#   lxc file push ./stacks/lncliweb/lncli-web.yml manager1/apps/lncliweb/lncli-web.yml
#   lxc file push ./stacks/lncliweb/lncli-web.lncliweb.conf.js manager1/apps/lncliweb/lncli-web.lncliweb.conf.js
#   lxc file push ./stacks/lncliweb/nginx.conf manager1/apps/lncliweb/nginx.conf

#   lxc exec manager1 -- docker stack deploy -c /apps/lncliweb/lncli-web.yml lncli-web
# fi