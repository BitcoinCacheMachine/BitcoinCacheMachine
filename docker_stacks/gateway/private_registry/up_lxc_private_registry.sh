#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying docker private registry to the 'bcm-cachestack'."
lxc exec bcm-gateway -- mkdir -p /apps/private_registry
lxc file push private_registry.yml bcm-gateway/apps/private_registry/private_registry.yml
lxc exec bcm-gateway -- docker stack deploy -c /apps/private_registry/private_registry.yml privateregistry