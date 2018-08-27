#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

echo "Building 'bcm-base' docker image on LXC host '$DOCKER_BUILD_LXC_COTAINER'. Consider using a BCM's Docker Registry."

lxc exec $DOCKER_BUILD_LXC_COTAINER -- mkdir -p /apps
lxc exec $DOCKER_BUILD_LXC_COTAINER -- mkdir -p /apps/bcm-base
lxc exec $DOCKER_BUILD_LXC_COTAINER -- docker pull ubuntu:bionic
lxc file push Dockerfile $DOCKER_BUILD_LXC_COTAINER/apps/bcm-base/Dockerfile
lxc exec $DOCKER_BUILD_LXC_COTAINER -- docker build -t bcm-base:latest /apps/bcm-base
