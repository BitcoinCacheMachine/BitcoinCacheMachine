#!/bin/bash

set -e

lxc copy $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME/BCMCachestackTemplate $BCM_LXC_CACHESTACK_CONTAINER_NAME

# create the docker backing for 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_attach_lxc_storage_to_container.sh $BCM_CACHESTACK_STORAGE_DOCKERVOL_CREATE $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME $BCM_CACHESTACK_STORAGE_DOCKERVOL_NAME"

lxc start $BCM_LXC_CACHESTACK_CONTAINER_NAME

# sleep 10

# # convert the host to allow swarm services. We only need the docker
# # endpoint to be accessible locally since we control everything through lxd API.
# if [[ $(lxc exec $BCM_LXC_CACHESTACK_CONTAINER_NAME -- docker info | grep "Swarm: inactive") ]]; then
#     echo "Initializing the docker swarm."
#     lxc exec $BCM_LXC_CACHESTACK_CONTAINER_NAME -- docker swarm init --advertise-addr eth0
# fi



# # Deploy the registry mirrors if specified.
# if [[ $BCM_CACHESTACK_REGISTRYMIRRORS_INSTALL = 'true' ]]; then
#     bash -c ./stacks/registry_mirrors/up_lxd_registrymirrors.sh
#     lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:5000
# fi

# # Deploy RSYNCD
# if [[ $BCM_CACHESTACK_RSYNCD_INSTALL = 'true' ]]; then
#     bash -c ./stacks/rsyncd/up_lxd_rsyncd.sh
# fi
    #bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/cachestack/squid/up_lxd_squid.sh bcm-gateway"

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

