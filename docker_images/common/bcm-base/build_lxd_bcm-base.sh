#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# the build context
LXD_BUILD_CONTAINER=$1

# how we're going to label our images
BCM_DOCKER_BUILD_DOMAIN_PREFIX=$2

echo "Building 'bcm-base' docker image on LXC host '$1'."

lxc exec $LXD_BUILD_CONTAINER -- mkdir -p /apps
lxc exec $LXD_BUILD_CONTAINER -- mkdir -p /apps/bcm-base
lxc exec $LXD_BUILD_CONTAINER -- docker pull ubuntu:bionic
lxc file push Dockerfile $LXD_BUILD_CONTAINER/apps/bcm-base/Dockerfile
lxc exec $LXD_BUILD_CONTAINER -- docker build -t "192.168.4.1/bcm-base:latest" /apps/bcm-base
lxc exec $LXD_BUILD_CONTAINER -- docker push "192.168.4.1/bcm-base:latest"