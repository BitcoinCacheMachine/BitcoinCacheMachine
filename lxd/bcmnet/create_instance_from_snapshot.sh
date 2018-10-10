#!/bin/bash

# the goal of this script is to get us a running instance named $1
# that's connected to either lxdGWLocalNet for standalone deployments
# or uses macvlan to connect to physical network interface.

set -eu

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"
export LXC_REMOTE=$(lxc remote get-default)
export LXC_HOST=$1
export STACK_NAME=$2
export CERT_CN=$3
export DIR=~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$STACK_NAME

lxc copy $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/bcmnet_template $LXC_HOST

lxc network attach lxdGWLocalNet $LXC_HOST eth0

# create the docker backing for 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_attach_lxc_storage_to_container.sh true $LXC_HOST $LXC_HOST-dockervol"

# make sure we configure the docker daemon.
lxc file push daemon.json $LXC_HOST/etc/docker/daemon.json

# push the client certificates up to the container before starting it
# https://docs.docker.com/engine/security/certificates/#creating-the-client-certificates


lxc start $LXC_HOST

bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/wait_for_dockerd.sh $LXC_HOST"

lxc exec $LXC_HOST -- mkdir -p /etc/docker/certs.d/bcmnet:5000

lxc file push $DIR/$CERT_CN.cert $LXC_HOST/etc/docker/certs.d/bcmnet:5000/client.cert
lxc file push $DIR/$CERT_CN.key $LXC_HOST/etc/docker/certs.d/bcmnet:5000/client.key
lxc file push ~/.bcm/certs/rootca.cert $LXC_HOST/etc/docker/certs.d/bcmnet:5000/ca.crt

lxc stop $LXC_HOST
lxc start $LXC_HOST
# lxc exec $INSTANCE_NAME -- systemctl enable docker
# lxc exec $INSTANCE_NAME -- systemctl start docker
# # convert the host to allow swarm services. We only need the docker
# # endpoint to be accessible locally since we control everything through lxd API.
# if [[ $(lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_NAME -- docker info | grep "Swarm: inactive") ]]; then
#     echo "Initializing the docker swarm."
#     lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_NAME -- docker swarm init --advertise-addr eth0
# fi



# # Deploy the registry mirrors if specified.
# if [[ $BCM_BCMNETTEMPLATE_REGISTRYMIRRORS_INSTALL = 'true' ]]; then
#     bash -c ./stacks/registry_mirrors/up_lxd_registrymirrors.sh
#     lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:5000
# fi

# # Deploy RSYNCD
# if [[ $BCM_BCMNETTEMPLATE_RSYNCD_INSTALL = 'true' ]]; then
#     bash -c ./stacks/rsyncd/up_lxd_rsyncd.sh
# fi
    #bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/cachestack/squid/up_lxd_squid.sh bcm-gateway"

# # Deploy IPFS Cache if specified.
# if [[ $BCM_BCMNETTEMPLATE_IPFSCACHE_INSTALL = 'true' ]]; then
#     # TODO refactor to subdirectory
#     echo "Deploying IPFS cache to the `cachestack`."
#     lxc exec cachestack -- mkdir -p /apps/ipfs_cache
#     lxc file push ./stacks/ipfs_cache/ipfs_cache.yml cachestack/apps/ipfs_cache/ipfs_cache.yml
#     lxc exec cachestack -- docker stack deploy -c /apps/ipfs_cache/ipfs_cache.yml ipfscache
# fi

# # Deploy a HTTP/HTTPS proxy based on squid if requested.
# if [[ $BCM_BCMNETTEMPLATE_SQUID_INSTALL = 'true' ]]; then
#     bash -c ./stacks/squid/up_lxd_squid.sh
# fi

# # Deploy a tor SOCKS5 proxy
# if [[ $BCM_BCMNETTEMPLATE_TOR_SOCKS5_PROXY_INSTALL = 'true' ]]; then
#     bash -c ./stacks/tor_socks5_proxy/up_lxd_torsocks5.sh
# fi


# # Deploy the bitcoind archival node if specified.
# if [[ $BCM_BCMNETTEMPLATE_BITCOIND_TESTNET_INSTALL = 'true' ]]; then
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



#     # update routes to prefer eth0 for outbound access.
#     lxc exec cachestack -- ifmetric eth0 0
# else
#     echo "LXD host 'cachestack' is already in a running state. Exiting."
#     exit 1
# fi

