#!/bin/bash

# This scripts builds all images for 'gateway'
# set the working directory to the location where the script is located
cd "$(dirname "$0")"

bash -c "$BCM_LOCAL_GIT_REPO/docker_images/common/bcm-base/build_lxd_bcm-base.sh"
#bash -c "./dnsmasq/build_dockerhub.sh"
#bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/bcm-squid/build_dockerhub.sh"