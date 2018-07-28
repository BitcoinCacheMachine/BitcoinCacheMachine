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
    # a bridged network created for outbound NAT for services on cachestack.
    lxc network create lxdbrCacheStack ipv4.nat=true
else
    echo "lxdbrCacheStack already exists."
fi

# create the lxdbrBCMBridge network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrBCMBridge) ]]; then
    # lxdbrBCMBridge connects cachestack services to BCM instances running in the same LXD daemon.
    lxc network create lxdbrBCMBridge ipv4.nat=false ipv6.nat=false ipv6.address=none
    #ipv4.address=10.254.254.1/24
else
    echo "lxdbrBCMBridge already exists."
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
fi

    
echo "Applying ./cachestack_lxd_profile.yml to lxd profile 'cachestackprofile'."
cat ./cachestack_lxd_profile.yml | lxc profile edit cachestackprofile

# Cache Stack Standalone 
if [[ $BC_ATTACH_TO_UNDERLAY = "true" ]]; then
    # if we're in standalone mode, then we attach eth3 in the container via MACVLAN
    # to the user-provided physical network interface that provides access to the network underlay. 
    # cachestack will obtain a unique IP address on the underlay and register its name as 'cachestack' 
    # with the local DNS server, if any.
    lxc profile device set cachestackprofile eth3 nictype macvlan
    lxc profile device set cachestackprofile eth3 parent $BCS_TRUSTED_HOST_INTERFACE
else
    lxc network create lxdBrNowhere ipv4.nat=false ipv6.nat=false
    lxc profile device set cachestackprofile eth3 nictype bridged
    lxc profile device set cachestackprofile eth3 parent lxdBrNowhere
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
    #lxc profile device add cachestackprofile root disk path=/ pool=$BC_ZFS_POOL_NAME
    lxc profile apply cachestack docker,cachestackprofile

    lxc start cachestack

    sleep 30

    # update routes to prefer eth0 for outbound access.
    lxc exec cachestack -- ifmetric eth0 0
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


