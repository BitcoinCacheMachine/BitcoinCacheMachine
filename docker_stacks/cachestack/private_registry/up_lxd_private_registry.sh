#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying docker private registry to the '$1'."
lxc exec $1 -- mkdir -p /apps/private_registry
lxc file push ./private_registry.yml $1/apps/private_registry/private_registry.yml
lxc exec $1 -- docker stack deploy -c /apps/private_registry/private_registry.yml privateregistry