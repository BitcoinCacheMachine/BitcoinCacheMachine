#!/bin/bash

# the goal of this script is to get us a running instance named $1
# that's connected to either bcmNet for standalone deployments

set -Eeuo pipefail

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"
LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$1
STACK_NAME=$2
CERT_CN=$3
DIR=$BCM_RUNTIME_DIR/runtime/$LXC_REMOTE/$LXC_HOST/$STACK_NAME

lxc copy $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/bcmnet_template $LXC_HOST

lxc network attach bcmNet $LXC_HOST eth0

# TODO need to attach dockervol

# make sure we configure the docker daemon.
lxc file push daemon.json $LXC_HOST/etc/docker/daemon.json

# push the client certificates up to the container before starting it
# https://docs.docker.com/engine/security/certificates/#creating-the-client-certificates


lxc start $LXC_HOST

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/wait_for_dockerd.sh --container-name=$LXC_HOST"

lxc exec $LXC_HOST -- mkdir -p /etc/docker/certs.d/bcmnet:5000

lxc file push $DIR/$CERT_CN.cert $LXC_HOST/etc/docker/certs.d/bcmnet:5000/client.cert
lxc file push $DIR/$CERT_CN.key $LXC_HOST/etc/docker/certs.d/bcmnet:5000/client.key
lxc file push $BCM_RUNTIME_DIR/certs/rootca.cert $LXC_HOST/etc/docker/certs.d/bcmnet:5000/ca.crt

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






######################3
# CAN PROBABLY DELETE
#

# # Apply the resulting profile and start the container.
# if [[ -z $(lxc list | grep cachestack | grep RUNNING) ]]; then
#     #lxc profile device add cachestackprofile root disk path=/ pool=$bcm_d1ata
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

