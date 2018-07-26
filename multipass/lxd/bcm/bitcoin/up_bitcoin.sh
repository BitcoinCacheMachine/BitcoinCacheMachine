#!/bin/bash

# quit script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# a bridged network created for all services residing on the LXC host 'bitcoin'
lxc network create lxdbrBitcoin ipv4.nat=true

lxc profile create bitcoinprofile
cat ./bitcoin_lxd_profile.yml | lxc profile edit bitcoinprofile

lxc copy dockertemplate/dockerSnapshot bitcoin
lxc profile apply bitcoin docker,bitcoinprofile

# Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
lxc storage create bitcoin-dockervol dir
lxc config device add bitcoin dockerdisk disk source=/var/lib/lxd/storage-pools/bitcoin-dockervol path=/var/lib/docker 

# push docker.json for registry mirror settings
lxc file push ./daemon.json bitcoin/etc/docker/daemon.json

lxc start bitcoin

sleep 10

WORKER_TOKEN=$(lxc exec manager1 -- docker swarm join-token worker | grep token | awk '{ print $5 }')

lxc exec bitcoin -- docker swarm join 10.0.0.11 --token $WORKER_TOKEN

# bind mount the bitcoin code directory into the manager1 lxc container
if [[ -z $(lxc config show manager1 | grep code_bitcoin) ]]; then
    echo "Bind mouting the bitcoin code directory to manager1/apps/bitcoin"
    lxc exec manager1 -- mkdir -p /apps/bitcoin
    lxc config device add manager1 code_bitcoin disk path=/apps/bitcoin source=$(pwd)/bitcoinstack
fi

# create the external bitcoind data volume
lxc exec bitcoin -- docker volume create bitcoind-data

# if IPFS_bootstrap is true, then we will download pre-indexed blockchain data, etc, via IPFS
# consider running a bitcoin cache stack on your local network to speed up deployment and avoid
# use of your internet connection.
if [[ $BCM_BITCOIN_IPFS_BOOTSTRAP = "true" ]]; then
    echo "Downloading a pre-validated and pre-indexed copy of the bitcoin blockchain."
    echo "WARNING: By using this method, you are trusting the developers of BCM as well as the computer that created the IPFS Hash!"
    echo "         Use for development purposes only unless you understand the risks and need to get a working BCM fast!  Consider adding"
    echo "         a bcm_cache_stack to your local network to improve deployment time and avoid Internet connection use."
    lxc exec bitcoin -- docker run -d --rm --name bitcoin_ipfs_bootstrapper -v bitcoind-data:/bitcoindata ipfs/go-ipfs:latest
    
    # wait for ipfs services to come online
    sleep 30

    if [ $BCM_BITCOIN_CHAIN = "testnet" ]; then
        echo "Calling ipfs get to download the bitcoin testnet pre-indexed block data."
        lxc exec bitcoin -- docker exec -it bitcoin_ipfs_bootstrapper ipfs get --output=/bitcoindata QmQftBHZwTa3phAEDLp1Cdx5pJG3gexjbeooZw9ogU1WcG
    elif [ $BCM_BITCOIN_CHAIN = "mainnet" ]; then
        # TODO - get hash of mainnet data for IPFS bootstrap
        lxc exec bitcoin -- docker exec -it bitcoin_ipfs_bootstrapper ipfs get GETHASHFORMAINNETDATA
    else
        echo "Wrong value set for BCM_BITCOIN_CHAIN environment variable."
        exit 1
    fi
fi

echo "Deploying bitcoind."
lxc exec manager1 -- docker stack deploy -c /apps/bitcoin/bitcoind/bitcoind.yml bitcoind

# Deploy lightningd
if [[ $BCM_BITCOIN_LIGHTNINGD = "true" ]]; then
    echo "BCM_BITCOIN_LIGHTNINGD set to true. Deploying lightningd."
    lxc exec manager1 -- docker stack deploy -c /apps/bitcoin/lightningd/lightningd.yml lightningd
fi

# Deploy lnd
if [[ $BCM_BITCOIN_LND = "true" ]]; then
    echo "BCM_BITCOIN_LND set to true. Deploying lnd."
    lxc exec manager1 -- docker stack deploy -c /apps/bitcoin/lnd/lnd.yml lnd
fi