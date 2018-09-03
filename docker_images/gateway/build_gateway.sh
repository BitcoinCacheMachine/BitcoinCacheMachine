#!/bin/bash

# This scripts builds all images for 'gateway'
# set the working directory to the location where the script is located
cd "$(dirname "$0")"

if [[ $(lxc list | grep $BCM_LXC_GATEWAY_CONTAINER_NAME) ]]; then
    #bash -c "$BCM_LOCAL_GIT_REPO/docker_images/common/bcm-base/build_lxd_bcm-base.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $BCM_DOCKER_BUILD_DOMAIN_IMAGE_PREFIX"
    #bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/bcm-dnsmasq/build_lxd_bcm-dnsmasq.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $BCM_DOCKER_BUILD_DOMAIN_IMAGE_PREFIX"
else
    #echo "Error. Ensure you pass a proper BCM_LXC_GATEWAY_CONTAINER_NAME context. Current invalid value is '$BCM_LXC_GATEWAY_CONTAINER_NAME'."
fi
