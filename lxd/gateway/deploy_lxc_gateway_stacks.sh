#!/bin/bash


# Deploy the private registry if specified.
if [[ $BCM_GATEWAY_STACKS_SQUID_DEPLOY = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/bcm-squid/build_lxd_bcm-squid.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $BCM_DOCKER_BUILD_DOMAIN_IMAGE_PREFIX"
    bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/gateway/squid/up_lxd_squid.sh"
    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 192.168.4.1:80
fi
