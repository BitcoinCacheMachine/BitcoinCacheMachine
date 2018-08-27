#!/bin/bash

# This scripts builds all images for 'gateway'
# set the working directory to the location where the script is located
cd "$(dirname "$0")"

env DOCKER_BUILD_LXC_COTAINER="gateway" bash -c ../build_lxd_bcm-base.sh

env DOCKER_BUILD_LXC_COTAINER="gateway" bash -c ./bcm-dnsmasq/build_lxd_bcm-dnsmasq.sh
