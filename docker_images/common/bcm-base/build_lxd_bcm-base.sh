#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

LXD_BUILD_CONTAINER=$1

echo "Building 'bcm-base' docker image on LXC host '$1'."

lxc exec $LXD_BUILD_CONTAINER -- mkdir -p /apps
lxc exec $LXD_BUILD_CONTAINER -- mkdir -p /apps/bcm-base
lxc exec $LXD_BUILD_CONTAINER -- docker pull ubuntu:bionic
lxc file push Dockerfile $LXD_BUILD_CONTAINER/apps/bcm-base/Dockerfile
lxc exec $LXD_BUILD_CONTAINER -- docker build -t bcm-base:latest /apps/bcm-base
