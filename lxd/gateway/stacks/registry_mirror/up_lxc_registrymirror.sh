#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Let's generate some HTTPS certificates for the new registry mirror.
bash -c "../../../shared/generate_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME registry_mirror"

echo "Deploying registry mirrors to the active LXD endpoint."
lxc exec bcm-gateway -- mkdir -p /apps/registry_mirror
lxc file push config.yml bcm-gateway/apps/registry_mirror/config.yml
lxc file push registry_mirror.yml bcm-gateway/apps/registry_mirror/registry_mirror.yml
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/registry_mirror/registry_mirror.cert bcm-gateway/apps/registry_mirror/regmirror.cert
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/registry_mirror/registry_mirror.key bcm-gateway/apps/registry_mirror/regmirror.key

lxc exec bcm-gateway -- env REGISTRY_HTTP_SECRET="CHANGEME" docker stack deploy -c /apps/registry_mirror/registry_mirror.yml registrymirror
