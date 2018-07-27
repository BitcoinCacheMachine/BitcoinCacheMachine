#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision Cache Stack
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

echo "Starting multipass/lxd/bcs/up_lxd.sh"

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# Create a docker host template if it doesn't exist already
if [[ -z $(lxc list | grep dockertemplate) ]]; then
    # Create a docker host template if it doesn't exist already
    if [[ -z $(lxc list | grep $BC_ZFS_POOL_NAME) ]]; then
        # create the host template if it doesn't exist already.
        bash -c ./host_template/up_lxd.sh
    fi

    # if the template doesn't exist, publish it create it.
    if [[ -z $(lxc image list | grep bctemplate) ]]; then
        echo "Publishing dockertemplate/dockerSnapshot snapshot as bctemplate lxd image."
        lxc publish $(lxc remote get-default):dockertemplate/dockerSnapshot --alias bctemplate
    fi
else
    echo "Skipping creation of the host template. Snapshot already exists."
fi

# create the lxdbrCacheStack network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrCacheStack) ]]; then
    # a bridged network created for outbound nAT.
    lxc network create lxdbrCacheStack ipv4.nat=true
else
    echo "lxdbrCacheStack already exists."
fi

# create the lxdbrBCMBridge network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrBCMBridge) ]]; then
    # lxdbrBCMBridge connects cachestack services to BCM instances running in the same LXD daemon.
    lxc network create lxdbrBCMBridge ipv4.nat=false
else
    echo "lxdbrCacheStack already exists."
fi

# create the lxdBCSMgrnet network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdBCSMgrnet) ]]; then
    # a network for docker swarm manager communication 
    # will probably implement this using VXLAN later
    lxc network create lxdBCSMgrnet ipv4.nat=false
else
    echo "lxdBCSMgrnet already exists."
fi

# create the cachestack container.
if [[ -z $(lxc list | grep cachestack) ]]; then
  lxc copy dockertemplate/dockerSnapshot cachestack
else
  echo "cachestack lxd container already exists."
fi

# create the cachestackprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep cachestackprofile) ]]; then
    lxc profile create cachestackprofile
    cat ./cachestack_lxd_profile.yml | lxc profile edit cachestackprofile
else
    echo "cachestackprofile lxd profile already exists."
fi

# Cache Stack Standalone 
if [[ $BC_CACHESTACK_STANDALONE = "true" ]]; then
    # if we're in standalone mode, eth2 in cachestack will connect to the underlay
    # via a physical interface as provided by the user in BCS_TRUSTED_HOST_INTERFACE
    echo "Attaching cachestack to the underlay via $BCS_TRUSTED_HOST_INTERFACE on $(lxc remote get-default)."
    lxc network attach-profile eno1 cachestackprofile eth2 eth2
else
    echo "Attaching Cache Stack lxd host to lxdbrBCMBridge to provide services to resident Bitcoin Cache Machine instances."
    lxc network attach lxdbrBCMBridge cachestack bcmbridge eth2
fi

# create the cachestack-dockervol storage pool.
if [[ -z $(lxc storage list | grep "cachestack-dockervol") ]]; then
    # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
    lxc storage create cachestack-dockervol dir
    lxc config device add cachestack dockerdisk disk source=/var/lib/lxd/storage-pools/cachestack-dockervol path=/var/lib/docker
else
  echo "cachestack-dockervol lxd storage pool already exists."
fi



# Apply the resulting profile and start the container.
if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
    # create a root device backed by the ZFS pool name passed in BC_ZFS_POOL_NAME.
    lxc profile device add cachestackprofile root disk path=/ pool=$BC_ZFS_POOL_NAME
    lxc profile apply cachestack docker,cachestackprofile

    # push docker.json. Not actually needed for cachestack at the moment.
    lxc file push ./daemon.json cachestack/etc/docker/daemon.json

    lxc start cachestack
    sleep 30
else
    echo "LXD host 'cachestack' is already in a running state. Exiting."
    exit 1
fi

# # CACHESTACK_INSIDE_IP is the IP that was assigned to the cachestack macvlan interface.
# CACHESTACK_INSIDE_IP=$(lxc exec cachestack -- ip address show dev eth1 | grep "inet " |  awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

# convert the host to allow swarm services. We only need the docker
# endpoint to be accessible locally since we control everything through lxd API.
lxc exec cachestack -- docker swarm init --advertise-addr=10.0.0.11 >>/dev/null

echo "Deploying Cache Stack services."

# Deploy the bitcoind archival node if specified.
if [[ $BCS_INSTALL_BITCOIND = 'true' ]]; then
    echo "Deploying a bitcoind archival node to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/bitcoind_archivalnode
    lxc file push ./stacks/bitcoind_archivalnode/bitcoind.yml cachestack/apps/bitcoind_archivalnode/bitcoind.yml
    lxc file push ./stacks/bitcoind_archivalnode/bitcoind-testnet.conf cachestack/apps/bitcoind_archivalnode/bitcoind-testnet.conf
    lxc file push ./stacks/bitcoind_archivalnode/bitcoind-torrc.conf cachestack/apps/bitcoind_archivalnode/bitcoind-torrc.conf
    lxc exec cachestack -- docker stack deploy -c /apps/bitcoind_archivalnode/bitcoind.yml bitcoind
fi

# Deploy IPFS Cache if specified.
if [[ $BCS_INSTALL_IPFSCACHE = 'true' ]]; then
    echo "Deploying IPFS cache to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/ipfs_cache
    lxc file push ./stacks/ipfs_cache/ipfs_cache.yml cachestack/apps/ipfs_cache/ipfs_cache.yml
    lxc exec cachestack -- docker stack deploy -c /apps/ipfs_cache/ipfs_cache.yml ipfscache
fi

# Deploy the private registry if specified.
if [[ $BCS_INSTALL_PRIVATEREGISTRY = 'true' ]]; then
    echo "Deploying docker private registry to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/private_registry
    lxc file push ./stacks/private_registry/private_registry.yml cachestack/apps/private_registry/private_registry.yml
    lxc exec cachestack -- docker stack deploy -c /apps/private_registry/private_registry.yml privateregistry
fi

# Deploy the registry mirrors if specified.
if [[ $BCS_INSTALL_REGISTRYMIRRORS = 'true' ]]; then
    echo "Deploying registry mirrors to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/registry_mirrors
    lxc file push ./stacks/registry_mirrors/registry_mirrors.yml cachestack/apps/registry_mirrors/registry_mirrors.yml
    lxc exec cachestack -- docker stack deploy -c /apps/registry_mirrors/registry_mirrors.yml registrymirrors
fi

# Deploy a HTTP/HTTPS proxy based on squid if requested.
if [[ $BCS_INSTALL_SQUID = 'true' ]]; then
    echo "Deploying squid HTTP/HTTPS proxy to the Cache Stack."
    lxc exec cachestack -- mkdir -p /apps/squid
    lxc file push ./stacks/squid/squid.yml cachestack/apps/squid/squid.yml
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


