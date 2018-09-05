#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Let's generate some HTTPS certificates for the new registry mirror.
bash -c "../../../shared/generate_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME private_registry bcmnet"

echo "Deploying private_registry to the active LXD endpoint."
lxc exec bcm-gateway -- mkdir -p /apps/private_registry
lxc file push config.yml bcm-gateway/apps/private_registry/config.yml
lxc file push private_registry.yml bcm-gateway/apps/private_registry/private_registry.yml
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/private_registry/private_registry.cert bcm-gateway/apps/private_registry/privreg.cert
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/private_registry/private_registry.key bcm-gateway/apps/private_registry/privreg.key
lxc exec bcm-gateway -- docker stack deploy -c /apps/private_registry/private_registry.yml privateregistry
# env REGISTRY_HTTP_SECRET="CHANGEME"