#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# if bcm-template lxc image exists, run the rest of the script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit 1
fi

# # create and populate the required networks
# bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_network_bridge_nat.sh $BCM_CACHESTACK_NETWORK_LXDBRGATEWAY_CREATE lxdbrCachestack"

# create an bcm-gateway-profile
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_profile.sh $BCM_CACHESTACK_PROFILE_CACHESTACK_STANDALONE_PROFILE_CREATE bcm-cachestack-standalone-profile $BCM_LOCAL_GIT_REPO/lxd/cachestack/cachestack_standlone_lxd_profile.yml"

# then update the profile with the user-specified interface
echo "Setting lxc profile 'bcm-cachestack-standalone-profile' eth0 to host interface '$BCM_CACHESTACK_STANDALONE_MACVLAN_PHYSICAL_INTERFACE'."
lxc profile device set bcm-cachestack-standalone-profile eth0 parent $BCM_CACHESTACK_STANDALONE_MACVLAN_PHYSICAL_INTERFACE

# create a cachestack template if it doesn't exist.
if [[ -z $(lxc list | grep "bcm-cachestack") ]]; then
    # let's generate a LXC template to base our lxc container on.
    lxc init bcm-template bcm-cachestack -p bcm_disk -p docker_privileged -p bcm-cachestack-standalone-profile
fi

lxc file push 10-lxc.yaml bcm-gateway/etc/netplan/10-lxc.yaml

lxc start bcm-cachestack
sleep 10
# CACHESTACK_INSIDE_IP is the IP that was assigned to the cachestack macvlan interface.
#CACHESTACK_INSIDE_IP=$(lxc exec bcm-cachestack -- ip address show dev eth0 | grep "inet " |  awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')
lxc exec bcm-cachestack -- mkdir -p /etc/systemd/system/docker.service.d
lxc file push https-proxy.conf bcm-cachestack/etc/systemd/system/docker.service.d/https-proxy.conf
lxc file push http-proxy.conf bcm-cachestack/etc/systemd/system/docker.service.d/http-proxy.conf
# lxc exec bcm-cachestack -- echo "HTTP_PROXY=http://gateway:3128/" >> /etc/environment
# lxc exec bcm-cachestack -- echo "HTTPS_PROXY=https://gateway:3128/" >> /etc/environment
lxc stop bcm-cachestack

# create the docker backing for 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_attach_lxc_storage_to_container.sh $BCM_CACHESTACK_STORAGE_DOCKERVOL_CREATE bcm-cachestack bcm-cachestack-dockervol"

lxc start bcm-cachestack

sleep 10

# convert the host to allow swarm services. We only need the docker
# endpoint to be accessible locally since we control everything through lxd API.
if [[ $(lxc exec bcm-cachestack -- docker info | grep "Swarm: inactive") ]]; then
    echo "Initializing the docker swarm."
    lxc exec bcm-cachestack -- docker swarm init
fi

# Deploy the private registry if specified.
if [[ $BCM_CACHESTACK_PRIVATEREGISTRY_INSTALL = 'true' ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/docker_images/common/bcm-base/build_lxd_bcm-base.sh bcm-cachestack"
    #bash -c "$BCM_LOCAL_GIT_REPO/docker_images/common/bcm-squid/build_lxd_bcm-squid.sh bcm-cachestack"
    bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/cachestack/private_registry/up_lxd_private_registry.sh bcm-cachestack"
    lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:80
fi

# # Deploy the registry mirrors if specified.
# if [[ $BCM_CACHESTACK_REGISTRYMIRRORS_INSTALL = 'true' ]]; then
#     bash -c ./stacks/registry_mirrors/up_lxd_registrymirrors.sh
#     lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:5000
# fi

# # Deploy RSYNCD
# if [[ $BCM_CACHESTACK_RSYNCD_INSTALL = 'true' ]]; then
#     bash -c ./stacks/rsyncd/up_lxd_rsyncd.sh
# fi

# # Deploy IPFS Cache if specified.
# if [[ $BCM_CACHESTACK_IPFSCACHE_INSTALL = 'true' ]]; then
#     # TODO refactor to subdirectory
#     echo "Deploying IPFS cache to the `cachestack`."
#     lxc exec cachestack -- mkdir -p /apps/ipfs_cache
#     lxc file push ./stacks/ipfs_cache/ipfs_cache.yml cachestack/apps/ipfs_cache/ipfs_cache.yml
#     lxc exec cachestack -- docker stack deploy -c /apps/ipfs_cache/ipfs_cache.yml ipfscache
# fi

# # Deploy a HTTP/HTTPS proxy based on squid if requested.
# if [[ $BCM_CACHESTACK_SQUID_INSTALL = 'true' ]]; then
#     bash -c ./stacks/squid/up_lxd_squid.sh
# fi

# # Deploy a tor SOCKS5 proxy
# if [[ $BCM_CACHESTACK_TOR_SOCKS5_PROXY_INSTALL = 'true' ]]; then
#     bash -c ./stacks/tor_socks5_proxy/up_lxd_torsocks5.sh
# fi


# # Deploy the bitcoind archival node if specified.
# if [[ $BCM_CACHESTACK_BITCOIND_TESTNET_INSTALL = 'true' ]]; then
#     bash -c ./stacks/bitcoind_archivalnode/up_lxd_bitcoind.sh
# fi





######################3
# CAN PROBABLY DELETE
#

# # Apply the resulting profile and start the container.
# if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
#     #lxc profile device add cachestackprofile root disk path=/ pool=$bcm_data
#     lxc profile apply cachestack default,cachestackprofile

#     # push necessary files to the template including daemon.json
#     lxc file push ./daemon.json cachestack/etc/docker/daemon.json

#     lxc start cachestack

#     sleep 30

#     # update routes to prefer eth0 for outbound access.
#     lxc exec cachestack -- ifmetric eth0 0
# else
#     echo "LXD host 'cachestack' is already in a running state. Exiting."
#     exit 1
# fi

