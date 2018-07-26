#!/bin/bash

# fail script if anything fails.
set -e

echo "Installing Cache Stack."

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# create the lxdbrCacheStack network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrCacheStack) ]]; then
    # a bridged network created for all services in CacheStack
    lxc network create lxdbrCacheStack ipv4.nat=true
else
  echo "lxdbrCacheStack already exists."
fi

# create the lxdbrCacheStack network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdBCSMgrnet) ]]; then
    # a network for docker swarm manager communication 
    # will probably implement this using VXLAN later
    lxc network create lxdBCSMgrnet ipv4.nat=false
else
  echo "lxdBCSMgrnet already exists."
fi


# create the cachestackprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep cachestackprofile) ]]; then
    lxc profile create cachestackprofile
else
  echo "cachestackprofile lxd profile already exists."
fi


# replace the literal text in ./cachestack_lxd_profile.yml with the user-provided (via lxd.env) physical 
# network adapter that connects to the underlay network. This is so we can map it to the macvlan interface
# on cachestack properly
sed 's/BCS_TRUSTED_HOST_INTERFACE/'$BCS_TRUSTED_HOST_INTERFACE'/g' ./cachestack_lxd_profile.yml  > ~/.bcs/"$(lxc remote get-default)"-cachestack_lxd_profile.runtime.yml
cat ~/.bcs/"$(lxc remote get-default)"-cachestack_lxd_profile.runtime.yml | lxc profile edit cachestackprofile


# create the cachestack container.
if [[ -z $(lxc list | grep cachestack) ]]; then
    lxc copy dockertemplate/dockerSnapshot cachestack
else
  echo "cachestack lxd container already exists."
fi


# create a root device backed by the ZFS pool name passed in BC_ZFS_POOL_NAME.
lxc profile device add cachestackprofile root disk path=/ pool=$BC_ZFS_POOL_NAME
lxc profile apply cachestack docker,cachestackprofile


# create the cachestack-dockervol storage pool.
if [[ -z $(lxc storage list | grep "cachestack-dockervol") ]]; then
    # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
    lxc storage create cachestack-dockervol dir
    lxc config device add cachestack dockerdisk disk source=/var/lib/lxd/storage-pools/cachestack-dockervol path=/var/lib/docker
else
  echo "cachestack-dockervol lxd storage pool already exists."
fi


# push docker.json. Not actually needed for cachestack at the moment.
lxc file push ./daemon.json cachestack/etc/docker/daemon.json


if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
    lxc start cachestack
    sleep 30
else
    echo "LXD host 'cachestack' is already in a running state. Exiting."
    exit 1
fi

# CACHESTACK_INSIDE_IP is the IP that was assigned to the cachestack macvlan interface.
CACHESTACK_INSIDE_IP=$(lxc exec cachestack -- ip address show dev eth1 | grep "inet " |  awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

# convert the host to allow swarm services. We only need the docker
# endpoint to be accessible locally since we control everything through lxd API.
lxc exec cachestack -- docker swarm init --advertise-addr=10.0.0.11 >>/dev/null

echo "Deploying Cache Stack services."

# Deploy the bitcoind archival node if specified.
if [[ $BCS_INSTALL_BITCOIND = 'true' ]]; then
    echo "Deploying a bitcoind archival node to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/bitcoind_archivalnode
    lxc file push ./bitcoind_archivalnode/bitcoind.yml cachestack/apps/bitcoind_archivalnode/bitcoind.yml
    lxc file push ./bitcoind_archivalnode/bitcoind-testnet.conf cachestack/apps/bitcoind_archivalnode/bitcoind-testnet.conf
    lxc file push ./bitcoind_archivalnode/bitcoind-torrc.conf cachestack/apps/bitcoind_archivalnode/bitcoind-torrc.conf
    lxc exec cachestack -- docker stack deploy -c /apps/bitcoind_archivalnode/bitcoind.yml bitcoind
fi

# Deploy IPFS Cache if specified.
if [[ $BCS_INSTALL_IPFSCACHE = 'true' ]]; then
    echo "Deploying IPFS cache to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/ipfs_cache
    lxc file push ./ipfs_cache/ipfs_cache.yml cachestack/apps/ipfs_cache/ipfs_cache.yml
    lxc exec cachestack -- docker stack deploy -c /apps/ipfs_cache/ipfs_cache.yml ipfscache
fi

# Deploy the private registry if specified.
if [[ $BCS_INSTALL_PRIVATEREGISTRY = 'true' ]]; then
    echo "Deploying docker private registry to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/private_registry
    lxc file push ./private_registry/private_registry.yml cachestack/apps/private_registry/private_registry.yml
    lxc exec cachestack -- docker stack deploy -c /apps/private_registry/private_registry.yml privateregistry
fi

# Deploy the registry mirrors if specified.
if [[ $BCS_INSTALL_REGISTRYMIRRORS = 'true' ]]; then
    echo "Deploying registry mirrors to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/registry_mirrors
    lxc file push ./registry_mirrors/registry_mirrors.yml cachestack/apps/registry_mirrors/registry_mirrors.yml
    lxc exec cachestack -- docker stack deploy -c /apps/registry_mirrors/registry_mirrors.yml registrymirrors
fi

# Deploy a HTTP/HTTPS proxy based on squid if requested.
if [[ $BCS_INSTALL_SQUID = 'true' ]]; then
    echo "Deploying squid HTTP/HTTPS proxy to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/squid
    lxc file push ./squid/squid.yml cachestack/apps/squid/squid.yml
    lxc exec cachestack -- docker stack deploy -c /apps/squid/squid.yml squid
fi


##################################
## THis is where we wait for services to come online before we declear the script 
## to be successful.

# Wait for archival node services
if [[ $BCS_INSTALL_BITCOIND = 'true' ]]; then
    # waiting for bitcoind P2P port TCP 18333.
    lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:18333
fi




# # provides local docker registry, elastic registry, and squid HTTP/HTTPS proxy/cache
# docker stack deploy -c ./bcm_cachestack.yml bcm_cachestack

# # wait for IPFS to come online
# wait-for-it -t 0 127.0.0.1:4001
# wait-for-it -t 0 127.0.0.1:8080
# wait-for-it -t 0 127.0.0.1:8081
# wait-for-it -t 0 127.0.0.1:4002
