#!/bin/bash

# This scripts builds all images for 'gateway'
# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# this is passed in; it's where we build the image.
# sometimes we need to build locally, but we should almost always
# use a temporary container and push images to a registry.
BUILD_CONTAINER=$1

if [[ $(lxc list | grep $BUILD_CONTAINER) ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/docker_images/common/bcm-base/build_lxd_bcm-base.sh $BUILD_CONTAINER"
    bash -c "$BCM_LOCAL_GIT_REPO/docker_images/common/bcm-tor/build_lxd_bcm-tor.sh $BUILD_CONTAINER"
    bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/bcm-squid/build_lxd_bcm-squid.sh $BUILD_CONTAINER"
    bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/bcm-dnsmasq/build_lxd_bcm-dnsmasq.sh $BUILD_CONTAINER"

else
    echo "Error. Ensure you pass a proper BUILD_CONTAINER context. Current invalid value is '$BUILD_CONTAINER'."
fi
