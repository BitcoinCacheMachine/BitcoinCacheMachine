#!/bin/bash

# remove registrymirror
if [[ $BCM_GATEWAY_STACKS_REGISTRYMIRROR_DEPLOY = "true" ]]; then
    bash -c "./registry_mirror/destroy_lxc_registrymirror.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
fi

# Deploy the private registry if specified.
if [[ $BCM_GATEWAY_STACKS_PRIVATEREGISTRY_DEPLOY = "true" ]]; then
    bash -c "./private_registry/destroy_lxc_privateregistry.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
fi

# Deploy squid
if [[ $BCM_GATEWAY_STACKS_SQUID_DEPLOY = "true" ]]; then
    bash -c "./squid/destroy_lxc_squid.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
fi
