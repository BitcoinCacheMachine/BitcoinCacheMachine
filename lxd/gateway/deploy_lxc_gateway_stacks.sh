#!/bin/bash


# let's slap a registry mirror pull through cache.
if [[ $BCM_GATEWAY_STACKS_REGISTRYMIRROR_DEPLOY = "true" ]]; then
    bash -c "./stacks/registry_mirror/up_lxc_registrymirror.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 192.168.4.1:5000
fi

# Deploy the private registry if specified.
if [[ $BCM_GATEWAY_STACKS_PRIVATEREGISTRY_DEPLOY = "true" ]]; then
    bash -c "./stacks/private_registry/up_lxc_private_registry.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 192.168.4.1:443
fi

# Deploy squid
if [[ $BCM_GATEWAY_STACKS_SQUID_DEPLOY = "true" ]]; then
    bash -c "./stacks/squid/up_lxc_squid.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 192.168.4.1:3128
fi
