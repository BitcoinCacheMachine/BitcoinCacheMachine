#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# create the lxdbrCacheStack network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrCacheStack) ]]; then
    # a bridged network created for outbound NAT for services on cachestack.
    lxc network create lxdbrCacheStack ipv4.nat=true
else
    echo "lxdbrCacheStack already exists."
fi

# create the lxdbrBCMCSBrdg network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrBCMCSBrdg) ]]; then
    # lxdbrBCMCSBrdg connects cachestack services to BCM instances running in the same LXD daemon.
    lxc network create lxdbrBCMCSBrdg ipv4.nat=false ipv6.nat=false ipv6.address=none
    #ipv4.address=10.254.254.1/24
else
    echo "lxdbrBCMCSBrdg already exists."
fi

# create the lxdBCMCSMGRNET network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdBCMCSMGRNET) ]]; then
    # a network for docker swarm manager communication 
    # will probably implement this using VXLAN later
    lxc network create lxdBCMCSMGRNET ipv4.nat=false
else
    echo "lxdBCMCSMGRNET already exists."
fi

# create the cachestackprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep cachestackprofile) ]]; then
    lxc profile create cachestackprofile
fi

echo "Applying ./cachestack_lxd_profile.yml to lxd profile 'cachestackprofile'."
cat ./cachestack_lxd_profile.yml | lxc profile edit cachestackprofile

# create the cachestack container.
if [[ -z $(lxc list | grep cachestack) ]]; then
    # if BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE is specified, we can init cachestack from the remote image
    # if it's not specified, then we initiailze cachestack from bcm-template residing locally.
    if [[ $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE = "none" ]] ; then
        lxc init bcm-template cachestack -p default -p docker_privileged -p cachestackprofile -s bcm_data
    else
        lxc init $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE:bcm-template cachestack -p default -p docker_privileged -p cachestackprofile -s bcm_data
    fi
else
  echo "cachestack lxc container already exists."
fi

# `cachestack` Standalone 
if [[ $BCM_CACHESTACK_ATTACH_TO_GATEWAY = "true" ]]; then
    # if we're in standalone mode, then we attach eth3 in the container via MACVLAN
    # to the user-provided physical network interface that provides access to the network gateway. 
    # cachestack will obtain a unique IP address on the gateway and register its name as 'cachestack' 
    # with the local DNS server, if any.
    lxc profile device set cachestackprofile eth3 nictype macvlan
    lxc profile device set cachestackprofile eth3 parent $BCS_TRUSTED_HOST_INTERFACE
else
    if [[ -z $(lxc network list | grep lxdBrNowhere) ]]; then
        lxc network create lxdBrNowhere ipv4.nat=false ipv6.nat=false
    fi

    
    lxc profile device set cachestackprofile eth3 nictype bridged
    lxc profile device set cachestackprofile eth3 parent lxdBrNowhere
fi


# create the cachestack-dockervol storage pool.
if [[ -z $(lxc storage list | grep "cachestack-dockervol") ]]; then
    # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
    lxc storage create cachestack-dockervol dir
    lxc config device add cachestack dockerdisk disk source=$(lxc storage show cachestack-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
else
    echo "cachestack-dockervol lxd storage pool already exists; attaching it to lxc container 'cachestack'."
    lxc config device add cachestack dockerdisk disk source=$(lxc storage show cachestack-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
fi

# Apply the resulting profile and start the container.
if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
    #lxc profile device add cachestackprofile root disk path=/ pool=$bcm_data
    lxc profile apply cachestack default,bcm_disk,cachestackprofile

    # push necessary files to the template including daemon.json
    lxc file push ./daemon.json cachestack/etc/docker/daemon.json

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
if [[ $(lxc exec cachestack -- docker info | grep "Swarm: inactive") ]]; then
    echo "Initializing the docker swarm."
    lxc exec cachestack -- docker swarm init --advertise-addr=10.254.253.11 >>/dev/null
fi

echo "Deploying `cachestack` services."

# Deploy the private registry if specified.
if [[ $BCS_INSTALL_PRIVATEREGISTRY = 'true' ]]; then
    bash -c ./stacks/private_registry/up_lxd_private_registry.sh
    lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:80
fi

# Deploy the registry mirrors if specified.
if [[ $BCS_INSTALL_REGISTRYMIRRORS = 'true' ]]; then
    bash -c ./stacks/registry_mirrors/up_lxd_registrymirrors.sh
    lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:5000
fi

# Deploy RSYNCD
if [[ $BCS_INSTALL_RSYNCD = 'true' ]]; then
    bash -c ./stacks/rsyncd/up_lxd_rsyncd.sh
fi

# Deploy IPFS Cache if specified.
if [[ $BCS_INSTALL_IPFSCACHE = 'true' ]]; then
    # TODO refactor to subdirectory
    echo "Deploying IPFS cache to the `cachestack`."
    lxc exec cachestack -- mkdir -p /apps/ipfs_cache
    lxc file push ./stacks/ipfs_cache/ipfs_cache.yml cachestack/apps/ipfs_cache/ipfs_cache.yml
    lxc exec cachestack -- docker stack deploy -c /apps/ipfs_cache/ipfs_cache.yml ipfscache
fi

# Deploy a HTTP/HTTPS proxy based on squid if requested.
if [[ $BCS_INSTALL_SQUID = 'true' ]]; then
    bash -c ./stacks/squid/up_lxd_squid.sh
fi

# Deploy a tor SOCKS5 proxy
if [[ $BCS_INSTALL_TOR_SOCKS5_PROXY = 'true' ]]; then
    bash -c ./stacks/tor_socks5_proxy/up_lxd_torsocks5.sh
fi


# Deploy the bitcoind archival node if specified.
if [[ $BCS_INSTALL_BITCOIND_TESTNET = 'true' ]]; then
    bash -c ./stacks/bitcoind_archivalnode/up_lxd_bitcoind.sh
fi

