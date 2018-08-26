#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying registry mirrors to the active LXD endpoint."
lxc exec cachestack -- mkdir -p /apps/registry_mirrors
lxc file push ./registry_mirrors.yml cachestack/apps/registry_mirrors/registry_mirrors.yml
lxc exec cachestack -- docker stack deploy -c /apps/registry_mirrors/registry_mirrors.yml registrymirrors
